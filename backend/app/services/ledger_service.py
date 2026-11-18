"""Financial ledger service enforcing strict accounting invariants and non-destructive entries."""

import uuid
from decimal import Decimal
from typing import Optional

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import (
    EntityNotFoundException,
    FinancialInvariantViolationException,
    InsufficientFundsException,
)
from app.models.enums import LedgerEntryType
from app.models.financial import EscrowCampaign, LedgerEntry


class LedgerService:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_escrow(self, campaign_id: uuid.UUID) -> EscrowCampaign:
        query = select(EscrowCampaign).where(EscrowCampaign.campaign_id == campaign_id)
        result = await self.db.execute(query)
        escrow = result.scalar_one_or_none()
        if not escrow:
            raise EntityNotFoundException("EscrowCampaign", campaign_id)
        return escrow

    def _verify_invariant(self, escrow: EscrowCampaign) -> None:
        """Verify: total_funded == total_available + total_reserved + total_claimed + total_refunded."""
        expected_funded = (
            escrow.total_available
            + escrow.total_reserved
            + escrow.total_claimed
            + escrow.total_refunded
        )
        if escrow.total_funded != expected_funded:
            raise FinancialInvariantViolationException(
                f"Funded ({escrow.total_funded}) != Available ({escrow.total_available}) + "
                f"Reserved ({escrow.total_reserved}) + Claimed ({escrow.total_claimed}) + "
                f"Refunded ({escrow.total_refunded})",
                extra={
                    "total_funded": str(escrow.total_funded),
                    "total_available": str(escrow.total_available),
                    "total_reserved": str(escrow.total_reserved),
                    "total_claimed": str(escrow.total_claimed),
                    "total_refunded": str(escrow.total_refunded),
                },
            )

    async def record_deposit(
        self,
        campaign_id: uuid.UUID,
        amount: Decimal,
        reference_id: str,
        onchain_campaign_id: Optional[str] = None,
        notes: Optional[str] = None,
    ) -> LedgerEntry:
        """Record on-chain deposit event, increasing total_funded and total_available."""
        if amount <= 0:
            raise ValueError("Deposit amount must be positive")

        # Check idempotency
        existing_query = select(LedgerEntry).where(LedgerEntry.reference_id == reference_id)
        existing = (await self.db.execute(existing_query)).scalar_one_or_none()
        if existing:
            return existing

        escrow = await self.get_escrow(campaign_id)
        if onchain_campaign_id:
            escrow.onchain_campaign_id = onchain_campaign_id

        # State mutation
        escrow.total_funded += amount
        escrow.total_available += amount

        self._verify_invariant(escrow)

        entry = LedgerEntry(
            escrow_campaign_id=escrow.id,
            entry_type=LedgerEntryType.DEPOSIT.value,
            amount=amount,
            running_available=escrow.total_available,
            running_reserved=escrow.total_reserved,
            running_claimed=escrow.total_claimed,
            running_refunded=escrow.total_refunded,
            reference_id=reference_id,
            notes=notes or f"On-chain deposit of {amount} cUSD",
        )
        self.db.add(entry)
        await self.db.flush()
        return entry

    async def reserve_payout(
        self,
        campaign_id: uuid.UUID,
        amount: Decimal,
        reference_id: str,
        notes: Optional[str] = None,
    ) -> LedgerEntry:
        """Reserve funds for an approved submission: moves amount from available to reserved."""
        if amount <= 0:
            raise ValueError("Reservation amount must be positive")

        existing_query = select(LedgerEntry).where(LedgerEntry.reference_id == reference_id)
        existing = (await self.db.execute(existing_query)).scalar_one_or_none()
        if existing:
            return existing

        escrow = await self.get_escrow(campaign_id)
        if escrow.total_available < amount:
            raise InsufficientFundsException(
                required=str(amount), available=str(escrow.total_available)
            )

        # State mutation
        escrow.total_available -= amount
        escrow.total_reserved += amount

        self._verify_invariant(escrow)

        entry = LedgerEntry(
            escrow_campaign_id=escrow.id,
            entry_type=LedgerEntryType.RESERVATION.value,
            amount=amount,
            running_available=escrow.total_available,
            running_reserved=escrow.total_reserved,
            running_claimed=escrow.total_claimed,
            running_refunded=escrow.total_refunded,
            reference_id=reference_id,
            notes=notes or f"Payout reserved for submission ({amount} cUSD)",
        )
        self.db.add(entry)
        await self.db.flush()
        return entry

    async def unreserve_payout(
        self,
        campaign_id: uuid.UUID,
        amount: Decimal,
        reference_id: str,
        notes: Optional[str] = None,
    ) -> LedgerEntry:
        """Return reserved funds to available pool (e.g. on revocation or dispute)."""
        if amount <= 0:
            raise ValueError("Unreservation amount must be positive")

        existing_query = select(LedgerEntry).where(LedgerEntry.reference_id == reference_id)
        existing = (await self.db.execute(existing_query)).scalar_one_or_none()
        if existing:
            return existing

        escrow = await self.get_escrow(campaign_id)
        if escrow.total_reserved < amount:
            raise FinancialInvariantViolationException(
                f"Cannot unreserve {amount} cUSD when total reserved is {escrow.total_reserved}"
            )

        escrow.total_reserved -= amount
        escrow.total_available += amount

        self._verify_invariant(escrow)

        entry = LedgerEntry(
            escrow_campaign_id=escrow.id,
            entry_type=LedgerEntryType.UNRESERVATION.value,
            amount=amount,
            running_available=escrow.total_available,
            running_reserved=escrow.total_reserved,
            running_claimed=escrow.total_claimed,
            running_refunded=escrow.total_refunded,
            reference_id=reference_id,
            notes=notes or f"Payout unreserved ({amount} cUSD)",
        )
        self.db.add(entry)
        await self.db.flush()
        return entry

    async def record_claim(
        self,
        campaign_id: uuid.UUID,
        amount: Decimal,
        reference_id: str,
        notes: Optional[str] = None,
    ) -> LedgerEntry:
        """Record contributor on-chain withdrawal: moves amount from reserved to claimed."""
        if amount <= 0:
            raise ValueError("Claim amount must be positive")

        existing_query = select(LedgerEntry).where(LedgerEntry.reference_id == reference_id)
        existing = (await self.db.execute(existing_query)).scalar_one_or_none()
        if existing:
            return existing

        escrow = await self.get_escrow(campaign_id)
        if escrow.total_reserved < amount:
            raise FinancialInvariantViolationException(
                f"Cannot claim {amount} cUSD when total reserved is {escrow.total_reserved}"
            )

        escrow.total_reserved -= amount
        escrow.total_claimed += amount

        self._verify_invariant(escrow)

        entry = LedgerEntry(
            escrow_campaign_id=escrow.id,
            entry_type=LedgerEntryType.CLAIM.value,
            amount=amount,
            running_available=escrow.total_available,
            running_reserved=escrow.total_reserved,
            running_claimed=escrow.total_claimed,
            running_refunded=escrow.total_refunded,
            reference_id=reference_id,
            notes=notes or f"On-chain claim executed ({amount} cUSD)",
        )
        self.db.add(entry)
        await self.db.flush()
        return entry

    async def record_refund(
        self,
        campaign_id: uuid.UUID,
        amount: Decimal,
        reference_id: str,
        notes: Optional[str] = None,
    ) -> LedgerEntry:
        """Record refund of remaining available funds to creator: moves from available to refunded."""
        if amount <= 0:
            raise ValueError("Refund amount must be positive")

        existing_query = select(LedgerEntry).where(LedgerEntry.reference_id == reference_id)
        existing = (await self.db.execute(existing_query)).scalar_one_or_none()
        if existing:
            return existing

        escrow = await self.get_escrow(campaign_id)
        if escrow.total_available < amount:
            raise InsufficientFundsException(
                required=str(amount), available=str(escrow.total_available)
            )

        escrow.total_available -= amount
        escrow.total_refunded += amount

        self._verify_invariant(escrow)

        entry = LedgerEntry(
            escrow_campaign_id=escrow.id,
            entry_type=LedgerEntryType.REFUND.value,
            amount=amount,
            running_available=escrow.total_available,
            running_reserved=escrow.total_reserved,
            running_claimed=escrow.total_claimed,
            running_refunded=escrow.total_refunded,
            reference_id=reference_id,
            notes=notes or f"Campaign refund of {amount} cUSD to creator",
        )
        self.db.add(entry)
        await self.db.flush()
        return entry
