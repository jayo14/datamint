"""Financial reconciliation engine verifying ledger integrity against on-chain smart contract state."""

import uuid
from datetime import datetime, timezone
from decimal import Decimal
from typing import List, Optional

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.exceptions import EntityNotFoundException
from app.models.campaign import DatasetCampaign
from app.models.enums import PayoutStatus
from app.models.financial import EscrowCampaign, LedgerEntry, PayoutAuthorization
from app.models.submission import Submission
from app.schemas.reconciliation import ReconciliationReport
from app.services.ledger_service import LedgerService


class ReconciliationService:
    """Service auditing escrow campaign financial integrity and flagging discrepancies."""

    def __init__(self, db: AsyncSession, ledger_service: Optional[LedgerService] = None):
        self.db = db
        self.ledger_service = ledger_service or LedgerService(db)

    async def reconcile_campaign(
        self,
        campaign_id: uuid.UUID,
        onchain_claimed_override: Optional[Decimal] = None,
        onchain_refunded_override: Optional[Decimal] = None,
    ) -> ReconciliationReport:
        """Audit single campaign ledger against math invariants and on-chain values."""
        query = (
            select(DatasetCampaign)
            .where(DatasetCampaign.id == campaign_id)
            .options(
                selectinload(DatasetCampaign.escrow).selectinload(EscrowCampaign.ledger_entries)
            )
        )
        campaign = (await self.db.execute(query)).scalar_one_or_none()
        if not campaign:
            raise EntityNotFoundException("DatasetCampaign", campaign_id)

        escrow = campaign.escrow
        if not escrow:
            raise EntityNotFoundException("EscrowCampaign for Campaign", campaign_id)

        discrepancies: List[str] = []

        # 1. Verify primary math invariant: Funded == Available + Reserved + Claimed + Refunded
        expected_funded = (
            escrow.total_available
            + escrow.total_reserved
            + escrow.total_claimed
            + escrow.total_refunded
        )
        invariant_holds = escrow.total_funded == expected_funded
        if not invariant_holds:
            discrepancies.append(
                f"Ledger invariant violation: Funded ({escrow.total_funded}) != sum of components ({expected_funded})"
            )

        # 2. Verify ledger journal matches summary escrow balances
        entries_query = select(LedgerEntry).where(LedgerEntry.escrow_campaign_id == escrow.id)
        entries = (await self.db.execute(entries_query)).scalars().all()

        calc_available = Decimal("0.0")
        calc_reserved = Decimal("0.0")
        calc_claimed = Decimal("0.0")
        calc_refunded = Decimal("0.0")
        calc_funded = Decimal("0.0")

        for e in entries:
            if e.entry_type == "DEPOSIT":
                calc_funded += e.amount
                calc_available += e.amount
            elif e.entry_type == "RESERVATION":
                calc_available -= e.amount
                calc_reserved += e.amount
            elif e.entry_type == "UNRESERVATION":
                calc_reserved -= e.amount
                calc_available += e.amount
            elif e.entry_type == "CLAIM":
                calc_reserved -= e.amount
                calc_claimed += e.amount
            elif e.entry_type == "REFUND":
                calc_available -= e.amount
                calc_refunded += e.amount

        if calc_funded != escrow.total_funded:
            discrepancies.append(
                f"Journal mismatch: Sum of deposits ({calc_funded}) != total_funded ({escrow.total_funded})"
            )
        if calc_claimed != escrow.total_claimed:
            discrepancies.append(
                f"Journal mismatch: Sum of claims ({calc_claimed}) != total_claimed ({escrow.total_claimed})"
            )
        if calc_reserved != escrow.total_reserved:
            discrepancies.append(
                f"Journal mismatch: Sum of reservations ({calc_reserved}) != total_reserved ({escrow.total_reserved})"
            )

        # 3. Check consistency of PayoutAuthorizations
        payouts_query = (
            select(PayoutAuthorization)
            .join(PayoutAuthorization.submission)
            .where(Submission.campaign_id == campaign_id)
        )
        payouts = (await self.db.execute(payouts_query)).scalars().all()
        claimed_vouchers_sum = sum(
            (p.amount for p in payouts if p.status == PayoutStatus.CLAIMED.value),
            Decimal("0.0"),
        )
        if claimed_vouchers_sum > escrow.total_claimed:
            discrepancies.append(
                f"Voucher claim mismatch: Sum of claimed vouchers ({claimed_vouchers_sum}) > escrow total_claimed ({escrow.total_claimed})"
            )

        # 4. Compare with on-chain values if provided
        if onchain_claimed_override is not None:
            if onchain_claimed_override != escrow.total_claimed:
                discrepancies.append(
                    f"On-chain mismatch: On-chain claimed ({onchain_claimed_override}) != Ledger claimed ({escrow.total_claimed})"
                )

        if onchain_refunded_override is not None:
            if onchain_refunded_override != escrow.total_refunded:
                discrepancies.append(
                    f"On-chain mismatch: On-chain refunded ({onchain_refunded_override}) != Ledger refunded ({escrow.total_refunded})"
                )

        is_reconciled = len(discrepancies) == 0

        return ReconciliationReport(
            campaign_id=campaign_id,
            onchain_campaign_id=escrow.onchain_campaign_id,
            is_reconciled=is_reconciled,
            invariant_holds=invariant_holds,
            total_funded=escrow.total_funded,
            total_available=escrow.total_available,
            total_reserved=escrow.total_reserved,
            total_claimed=escrow.total_claimed,
            total_refunded=escrow.total_refunded,
            onchain_claimed_amount=onchain_claimed_override,
            onchain_refunded_amount=onchain_refunded_override,
            discrepancies=discrepancies,
            timestamp=datetime.now(timezone.utc),
        )

    async def reconcile_all_campaigns(self) -> List[ReconciliationReport]:
        """Audit all campaigns in system."""
        query = select(DatasetCampaign.id)
        campaign_ids = (await self.db.execute(query)).scalars().all()

        reports: List[ReconciliationReport] = []
        for c_id in campaign_ids:
            report = await self.reconcile_campaign(c_id)
            reports.append(report)
        return reports
