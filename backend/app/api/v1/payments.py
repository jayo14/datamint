"""Payments, payout vouchers, and campaign ledger audit endpoints."""

import uuid
from typing import List
from fastapi import APIRouter, Depends, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.api.deps import get_current_user
from app.core.database import get_db
from app.models.enums import PayoutStatus
from app.models.financial import LedgerEntry, PayoutAuthorization
from app.models.identity import User
from app.schemas.ledger import LedgerEntryResponse, PayoutVoucherResponse
from app.services.ledger_service import LedgerService

router = APIRouter(prefix="/payments", tags=["Payments & Ledger"])


@router.get("/vouchers", response_model=List[PayoutVoucherResponse], status_code=status.HTTP_200_OK)
async def list_pending_vouchers(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> List[PayoutVoucherResponse]:
    """List claimable EIP-712 payout vouchers for the authenticated contributor."""
    query = (
        select(PayoutAuthorization)
        .where(
            PayoutAuthorization.contributor_id == current_user.id,
            PayoutAuthorization.status == PayoutStatus.AUTHORIZED.value,
        )
        .order_by(PayoutAuthorization.created_at.desc())
    )
    result = await db.execute(query)
    return [PayoutVoucherResponse.model_validate(p) for p in result.scalars().all()]


@router.get("/ledger/{campaign_id}", response_model=List[LedgerEntryResponse], status_code=status.HTTP_200_OK)
async def get_campaign_ledger(
    campaign_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
) -> List[LedgerEntryResponse]:
    """Retrieve the full double-entry audit ledger for a campaign."""
    service = LedgerService(db)
    escrow = await service.get_escrow(campaign_id)

    query = (
        select(LedgerEntry)
        .where(LedgerEntry.escrow_campaign_id == escrow.id)
        .order_by(LedgerEntry.created_at.asc())
    )
    result = await db.execute(query)
    return [LedgerEntryResponse.model_validate(e) for e in result.scalars().all()]
