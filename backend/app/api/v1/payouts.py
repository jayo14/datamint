"""EIP-712 reward vouchers and payout claim recording endpoints."""

from __future__ import annotations

import uuid
from decimal import Decimal
from typing import Any

from fastapi import APIRouter, Depends, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user
from app.core.config import settings
from app.core.database import get_db
from app.core.exceptions import ConflictOfInterestException, EntityNotFoundException
from app.models.identity import User
from app.models.submission import Submission
from app.schemas.payout import ClaimSubmissionRequest, PayoutVoucherResponse, RewardVoucherData
from app.services.payout_signer import PayoutSignerService

router = APIRouter(prefix="/payouts", tags=["Payouts & Vouchers"])


def _build_voucher(payout: Any) -> RewardVoucherData:
    """Construct an EIP-712 voucher from a payout authorization record."""
    amount_wei = int(payout.amount * Decimal(10**18))
    return RewardVoucherData.model_validate(
        {
            "campaignId": payout.onchain_campaign_id or "0x" + "0" * 64,
            "contributor": payout.recipient_address,
            "amount": str(amount_wei),
            "amount_wei": amount_wei,
            "nonce": payout.nonce or "0x" + "0" * 64,
            "deadline": payout.deadline or int(payout.expires_at.timestamp()),
        }
    )


@router.get(
    "/submissions/{submission_id}/voucher",
    response_model=PayoutVoucherResponse,
    status_code=status.HTTP_200_OK,
)
async def get_or_generate_voucher(
    submission_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> PayoutVoucherResponse:
    """Retrieve or generate an EIP-712 reward voucher for an approved submission."""
    # Enforce object-level access control before generating voucher or mutating state
    sub_query = select(Submission).where(Submission.id == submission_id)
    submission = (await db.execute(sub_query)).scalar_one_or_none()
    if not submission:
        raise EntityNotFoundException("Submission", submission_id)

    if submission.contributor_id != current_user.id:
        raise ConflictOfInterestException(
            "Only the contributor can access their reward authorization voucher."
        )

    service = PayoutSignerService(db)
    payout = await service.generate_payout_voucher(submission_id)
    await db.commit()

    voucher_data = _build_voucher(payout)

    return PayoutVoucherResponse(
        id=payout.id,
        submission_id=payout.submission_id,
        contributor_id=payout.contributor_id,
        amount=payout.amount,
        recipient_address=payout.recipient_address,
        status=payout.status,
        expires_at=payout.expires_at,
        voucher=voucher_data,
        signature=payout.signature,
        contract_address=settings.ESCROW_CONTRACT_ADDRESS,
        chain_id=settings.CELO_CHAIN_ID,
    )


@router.post(
    "/submissions/{submission_id}/claim",
    response_model=PayoutVoucherResponse,
    status_code=status.HTTP_200_OK,
)
async def record_claim_broadcast(
    submission_id: uuid.UUID,
    payload: ClaimSubmissionRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> PayoutVoucherResponse:
    """Record on-chain claim transaction hash submitted by contributor."""
    # Enforce object-level access control before recording claim transaction
    sub_query = select(Submission).where(Submission.id == submission_id)
    submission = (await db.execute(sub_query)).scalar_one_or_none()
    if not submission:
        raise EntityNotFoundException("Submission", submission_id)

    if submission.contributor_id != current_user.id:
        raise ConflictOfInterestException("Unauthorized contributor for claim record.")

    service = PayoutSignerService(db)
    payout = await service.record_claim_submission(
        submission_id=submission_id,
        claim_tx_hash=payload.claim_tx_hash,
    )
    await db.commit()

    voucher_data = _build_voucher(payout)

    return PayoutVoucherResponse(
        id=payout.id,
        submission_id=payout.submission_id,
        contributor_id=payout.contributor_id,
        amount=payout.amount,
        recipient_address=payout.recipient_address,
        status=payout.status,
        expires_at=payout.expires_at,
        voucher=voucher_data,
        signature=payout.signature,
        contract_address=settings.ESCROW_CONTRACT_ADDRESS,
        chain_id=settings.CELO_CHAIN_ID,
    )
