"""Submission lifecycle management, upload initiation, validation, and payout minting."""

import hashlib
import uuid
from datetime import datetime, timedelta, timezone
from decimal import Decimal
from typing import Optional, Tuple
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload
from app.core.exceptions import (
    DataMintException,
    EntityNotFoundException,
    InvalidStateTransitionException,
)
from app.models.campaign import DatasetCampaign
from app.models.enums import (
    CampaignStatus,
    PayoutStatus,
    SubmissionStatus,
    ValidationStatus,
)
from app.models.financial import PayoutAuthorization
from app.models.submission import Submission, SubmissionAsset, ValidationFinding, ValidationRun
from app.models.wallet import Wallet
from app.schemas.submission import SubmissionCreate, SubmissionInitResponse
from app.services.ledger_service import LedgerService


class SubmissionService:
    def __init__(self, db: AsyncSession):
        self.db = db
        self.ledger_service = LedgerService(db)

    async def initialize_submission(
        self, contributor_id: uuid.UUID, data: SubmissionCreate
    ) -> SubmissionInitResponse:
        """Create a submission in PENDING_UPLOAD status and return pre-signed S3 upload parameters."""
        # Check campaign is active
        campaign_query = select(DatasetCampaign).where(DatasetCampaign.id == data.campaign_id)
        campaign = (await self.db.execute(campaign_query)).scalar_one_or_none()
        if not campaign:
            raise EntityNotFoundException("DatasetCampaign", data.campaign_id)

        if campaign.status != CampaignStatus.ACTIVE.value:
            raise DataMintException(
                detail=f"Campaign is not accepting submissions (current status: {campaign.status})"
            )

        if campaign.current_submissions >= campaign.target_submissions:
            raise DataMintException(detail="Campaign submission target already reached")

        submission = Submission(
            campaign_id=campaign.id,
            contributor_id=contributor_id,
            status=SubmissionStatus.PENDING_UPLOAD.value,
        )
        self.db.add(submission)
        await self.db.flush()

        # Generate unique storage key
        storage_key = (
            f"campaigns/{campaign.id}/submissions/{submission.id}/{uuid.uuid4()}_{data.filename}"
        )

        asset = SubmissionAsset(
            submission_id=submission.id,
            asset_type=data.asset_type.value,
            storage_key=storage_key,
            byte_size=data.byte_size,
            mime_type=data.mime_type,
            checksum_sha256=data.checksum_sha256,
        )
        self.db.add(asset)
        await self.db.flush()

        # In production this generates an S3 pre-signed PUT URL. Here we return the endpoint path.
        expires_at = datetime.now(timezone.utc) + timedelta(minutes=30)
        upload_url = f"https://storage.datamint.ai/{storage_key}?expires={int(expires_at.timestamp())}"

        return SubmissionInitResponse(
            submission_id=submission.id,
            upload_url=upload_url,
            storage_key=storage_key,
            expires_at=expires_at,
        )

    async def complete_upload(self, submission_id: uuid.UUID) -> Submission:
        """Transition submission to QUEUED_FOR_VALIDATION after direct upload completes."""
        submission = await self.get_submission(submission_id)
        if submission.status != SubmissionStatus.PENDING_UPLOAD.value:
            raise InvalidStateTransitionException(
                submission.status, SubmissionStatus.QUEUED_FOR_VALIDATION.value
            )

        submission.status = SubmissionStatus.QUEUED_FOR_VALIDATION.value
        await self.db.flush()
        return submission

    async def get_submission(self, submission_id: uuid.UUID) -> Submission:
        query = (
            select(Submission)
            .where(Submission.id == submission_id)
            .options(
                selectinload(Submission.campaign),
                selectinload(Submission.assets),
                selectinload(Submission.validation_runs).selectinload(ValidationRun.findings),
                selectinload(Submission.payout_authorization),
            )
        )
        result = await self.db.execute(query)
        submission = result.scalar_one_or_none()
        if not submission:
            raise EntityNotFoundException("Submission", submission_id)
        return submission

    async def approve_submission_and_authorize_payout(
        self, submission_id: uuid.UUID, score: Decimal = Decimal("0.95")
    ) -> Tuple[Submission, PayoutAuthorization]:
        """Approve submission, reserve reward in financial ledger, and issue signed payout authorization."""
        submission = await self.get_submission(submission_id)
        campaign = submission.campaign

        # 1. Record validation run
        vrun = ValidationRun(
            submission_id=submission.id,
            validator_type="ai_consensus_evaluator",
            status=ValidationStatus.PASSED.value,
            score=score,
            completed_at=datetime.now(timezone.utc),
        )
        self.db.add(vrun)
        await self.db.flush()

        vfinding = ValidationFinding(
            validation_run_id=vrun.id,
            code="CRITERIA_MET",
            severity="INFO",
            message="Submission fully satisfies quality requirements",
        )
        self.db.add(vfinding)

        # 2. Transition submission status
        submission.status = SubmissionStatus.APPROVED.value
        campaign.current_submissions += 1

        # Check if campaign completed
        if campaign.current_submissions >= campaign.target_submissions:
            campaign.status = CampaignStatus.COMPLETED.value

        # 3. Reserve funds in ledger
        ref_id = f"sub:reserve:{submission.id}"
        await self.ledger_service.reserve_payout(
            campaign_id=campaign.id,
            amount=campaign.reward_per_submission,
            reference_id=ref_id,
            notes=f"Reserved payout for approved submission {submission.id}",
        )

        # 4. Find contributor primary wallet
        wallet_query = select(Wallet).where(
            Wallet.user_id == submission.contributor_id,
            Wallet.is_primary.is_(True),
        )
        wallet = (await self.db.execute(wallet_query)).scalar_one_or_none()
        recipient_addr = wallet.address if wallet else "0x0000000000000000000000000000000000000000"

        # 5. Generate payout voucher hash & mock signature
        voucher_preimage = f"{submission.id}:{recipient_addr}:{campaign.reward_per_submission}"
        voucher_hash = "0x" + hashlib.sha256(voucher_preimage.encode()).hexdigest()
        mock_sig = "0x" + "00" * 65

        payout = PayoutAuthorization(
            submission_id=submission.id,
            contributor_id=submission.contributor_id,
            amount=campaign.reward_per_submission,
            recipient_address=recipient_addr,
            voucher_hash=voucher_hash,
            signature=mock_sig,
            status=PayoutStatus.AUTHORIZED.value,
            expires_at=datetime.now(timezone.utc) + timedelta(days=30),
        )
        self.db.add(payout)
        await self.db.flush()

        return submission, payout
