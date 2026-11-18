"""Submission lifecycle, concurrency-safe capacity locks, and secure media orchestration service."""

import hashlib
import uuid
from datetime import datetime, timedelta, timezone
from decimal import Decimal
from typing import List, Optional, Tuple
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload
from app.core.exceptions import (
    DataMintException,
    EntityNotFoundException,
    InvalidStateTransitionException,
)
from app.models.campaign import DatasetCampaign
from app.models.enums import (
    AssetType,
    CampaignStatus,
    PayoutStatus,
    SubmissionStatus,
    ValidationStatus,
)
from app.models.financial import PayoutAuthorization
from app.models.submission import Submission, SubmissionAsset, ValidationFinding, ValidationRun
from app.models.wallet import Wallet
from app.schemas.submission import (
    SubmissionCreate,
    SubmissionDraftCreate,
    SubmissionDraftUpdate,
    SubmissionInitResponse,
)
from app.services.ledger_service import LedgerService
from app.services.storage_service import sanitize_filename, storage_provider, validate_file_specs


class SubmissionService:
    def __init__(self, db: AsyncSession):
        self.db = db
        self.ledger_service = LedgerService(db)

    async def create_draft(
        self, contributor_id: uuid.UUID, data: SubmissionDraftCreate
    ) -> Submission:
        """Create a new draft submission for an active campaign."""
        campaign = await self._get_active_campaign(data.campaign_id)

        submission = Submission(
            campaign_id=campaign.id,
            contributor_id=contributor_id,
            status=SubmissionStatus.DRAFT.value,
            draft_data=data.draft_data,
            metadata_json=data.metadata_json,
        )
        self.db.add(submission)
        await self.db.flush()
        return await self.get_submission(submission.id)

    async def update_draft(
        self, submission_id: uuid.UUID, contributor_id: uuid.UUID, data: SubmissionDraftUpdate
    ) -> Submission:
        """Update draft submission data before finalization."""
        submission = await self.get_submission(submission_id)

        if submission.contributor_id != contributor_id:
            raise DataMintException(detail="Unauthorized: You cannot edit another contributor's submission")

        if submission.status not in (SubmissionStatus.DRAFT.value, SubmissionStatus.PENDING_UPLOAD.value):
            raise DataMintException(
                detail=f"Submission is {submission.status} and cannot be modified after final submission",
                code="SUBMISSION_IMMUTABLE",
            )

        if data.draft_data is not None:
            submission.draft_data = data.draft_data
        if data.metadata_json is not None:
            submission.metadata_json = data.metadata_json

        await self.db.flush()
        return submission

    async def request_upload_url(
        self,
        submission_id: uuid.UUID,
        contributor_id: uuid.UUID,
        filename: str,
        mime_type: str,
        byte_size: int,
        asset_type: AssetType = AssetType.AUDIO,
        checksum_sha256: Optional[str] = None,
    ) -> SubmissionInitResponse:
        """Authorize file upload, generate safe storage key, and issue presigned S3 upload URL."""
        submission = await self.get_submission(submission_id)

        if submission.contributor_id != contributor_id:
            raise DataMintException(detail="Unauthorized: You cannot upload assets to another contributor's submission")

        if submission.status not in (SubmissionStatus.DRAFT.value, SubmissionStatus.PENDING_UPLOAD.value):
            raise DataMintException(detail="Cannot upload assets to an already submitted or settled task")

        # Validate MIME type and size against campaign data type
        validate_file_specs(
            data_type=submission.campaign.data_type,
            mime_type=mime_type,
            byte_size=byte_size,
        )

        safe_name = sanitize_filename(filename)
        storage_key = f"campaigns/{submission.campaign_id}/submissions/{submission.id}/{uuid.uuid4()}_{safe_name}"

        # Register asset record
        asset = SubmissionAsset(
            submission_id=submission.id,
            asset_type=asset_type.value,
            storage_key=storage_key,
            byte_size=byte_size,
            mime_type=mime_type,
            checksum_sha256=checksum_sha256,
            is_uploaded=False,
        )
        self.db.add(asset)

        # Transition status to PENDING_UPLOAD if in DRAFT
        if submission.status == SubmissionStatus.DRAFT.value:
            submission.status = SubmissionStatus.PENDING_UPLOAD.value

        await self.db.flush()

        expires_at = datetime.now(timezone.utc) + timedelta(minutes=30)
        upload_url = storage_provider.generate_presigned_upload_url(
            object_key=storage_key,
            mime_type=mime_type,
            max_size_bytes=byte_size,
            expires_in_seconds=1800,
        )

        return SubmissionInitResponse(
            submission_id=submission.id,
            upload_url=upload_url,
            storage_key=storage_key,
            expires_at=expires_at,
        )

    async def confirm_upload(
        self, submission_id: uuid.UUID, contributor_id: uuid.UUID, asset_id: uuid.UUID
    ) -> SubmissionAsset:
        """Confirm direct S3 upload completion and verify object exists."""
        submission = await self.get_submission(submission_id)

        if submission.contributor_id != contributor_id:
            raise DataMintException(detail="Unauthorized: You cannot confirm uploads for another user")

        asset_query = select(SubmissionAsset).where(
            SubmissionAsset.id == asset_id,
            SubmissionAsset.submission_id == submission_id,
        )
        asset = (await self.db.execute(asset_query)).scalar_one_or_none()
        if not asset:
            raise EntityNotFoundException("SubmissionAsset", asset_id)

        # Verify object exists in storage
        if not storage_provider.verify_object_exists(asset.storage_key):
            raise DataMintException(
                detail="Uploaded object was not found in storage bucket",
                code="OBJECT_NOT_FOUND",
            )

        asset.is_uploaded = True
        asset.uploaded_at = datetime.now(timezone.utc)
        await self.db.flush()
        return asset

    async def submit_for_validation(
        self, submission_id: uuid.UUID, contributor_id: uuid.UUID
    ) -> Submission:
        """
        Finalize submission with concurrency-safe row-level locking on campaign capacity.
        Transitions state to SUBMITTED -> PENDING_VALIDATION.
        """
        # Lock campaign row to prevent race conditions when close to capacity
        submission = await self.get_submission(submission_id)
        if submission.contributor_id != contributor_id:
            raise DataMintException(detail="Unauthorized: You cannot finalize another contributor's submission")

        if submission.status not in (SubmissionStatus.DRAFT.value, SubmissionStatus.PENDING_UPLOAD.value):
            raise InvalidStateTransitionException(submission.status, SubmissionStatus.SUBMITTED.value)

        # Atomic capacity check with row lock
        campaign_query = (
            select(DatasetCampaign)
            .where(DatasetCampaign.id == submission.campaign_id)
            .with_for_update()
        )
        campaign = (await self.db.execute(campaign_query)).scalar_one()

        if campaign.status != CampaignStatus.ACTIVE.value:
            raise DataMintException(
                detail=f"Campaign is no longer active (current status: {campaign.status})"
            )

        if campaign.current_submissions >= campaign.target_submissions:
            raise DataMintException(
                detail="Campaign capacity reached: No further submissions can be accepted",
                code="CAPACITY_REACHED",
            )

        # Verify that at least one asset is marked uploaded if media required
        if submission.campaign.data_type in ("VOICE", "IMAGE"):
            uploaded_assets = [a for a in submission.assets if a.is_uploaded]
            if not uploaded_assets:
                # If unconfirmed, attempt auto-check
                for a in submission.assets:
                    if storage_provider.verify_object_exists(a.storage_key):
                        a.is_uploaded = True
                        a.uploaded_at = datetime.now(timezone.utc)
                if not any(a.is_uploaded for a in submission.assets):
                    raise DataMintException(
                        detail="Cannot submit: No media file has been successfully uploaded",
                        code="NO_UPLOADED_ASSETS",
                    )

        # Finalize submission
        submission.status = SubmissionStatus.PENDING_VALIDATION.value
        submission.submitted_at = datetime.now(timezone.utc)

        # Note: current_submissions counter is incremented upon submission acceptance or reservation
        campaign.current_submissions += 1
        if campaign.current_submissions >= campaign.target_submissions:
            campaign.status = CampaignStatus.COMPLETED.value

        await self.db.flush()
        return submission

    async def get_media_download_url(
        self, submission_id: uuid.UUID, asset_id: uuid.UUID, requesting_user_id: uuid.UUID
    ) -> str:
        """Issue secure, short-lived presigned download URL with strict object-level access control."""
        submission = await self.get_submission(submission_id)

        # Authorization: caller MUST be the contributor or the campaign creator
        is_contributor = submission.contributor_id == requesting_user_id
        is_creator = submission.campaign.creator_id == requesting_user_id

        if not is_contributor and not is_creator:
            raise DataMintException(
                detail="Forbidden: You do not have permission to access this submission's media",
                code="FORBIDDEN_MEDIA_ACCESS",
            )

        asset = next((a for a in submission.assets if a.id == asset_id), None)
        if not asset:
            raise EntityNotFoundException("SubmissionAsset", asset_id)

        return storage_provider.generate_presigned_download_url(
            object_key=asset.storage_key, expires_in_seconds=1800
        )

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

    async def list_contributor_submissions(
        self, contributor_id: uuid.UUID, campaign_id: Optional[uuid.UUID] = None, page: int = 1, page_size: int = 20
    ) -> Tuple[List[Submission], int]:
        """List submissions authored by the authenticated contributor."""
        base_query = select(Submission).where(Submission.contributor_id == contributor_id)
        if campaign_id:
            base_query = base_query.where(Submission.campaign_id == campaign_id)

        count_query = select(func.count()).select_from(base_query.subquery())
        total = (await self.db.execute(count_query)).scalar_one()

        items_query = (
            base_query.options(
                selectinload(Submission.campaign),
                selectinload(Submission.assets),
                selectinload(Submission.validation_runs),
            )
            .order_by(Submission.created_at.desc())
            .offset((page - 1) * page_size)
            .limit(page_size)
        )
        result = await self.db.execute(items_query)
        return list(result.scalars().all()), total

    async def list_campaign_submissions(
        self, campaign_id: uuid.UUID, creator_id: uuid.UUID, page: int = 1, page_size: int = 20
    ) -> Tuple[List[Submission], int]:
        """List submissions for a campaign. Caller must be the campaign creator."""
        campaign_query = select(DatasetCampaign).where(DatasetCampaign.id == campaign_id)
        campaign = (await self.db.execute(campaign_query)).scalar_one_or_none()
        if not campaign:
            raise EntityNotFoundException("DatasetCampaign", campaign_id)

        if campaign.creator_id != creator_id:
            raise DataMintException(detail="Forbidden: You are not the creator of this campaign")

        base_query = select(Submission).where(Submission.campaign_id == campaign_id)

        count_query = select(func.count()).select_from(base_query.subquery())
        total = (await self.db.execute(count_query)).scalar_one()

        items_query = (
            base_query.options(
                selectinload(Submission.campaign),
                selectinload(Submission.assets),
                selectinload(Submission.validation_runs),
            )
            .order_by(Submission.created_at.desc())
            .offset((page - 1) * page_size)
            .limit(page_size)
        )
        result = await self.db.execute(items_query)
        return list(result.scalars().all()), total

    async def _get_active_campaign(self, campaign_id: uuid.UUID) -> DatasetCampaign:
        query = select(DatasetCampaign).where(DatasetCampaign.id == campaign_id)
        campaign = (await self.db.execute(query)).scalar_one_or_none()
        if not campaign:
            raise EntityNotFoundException("DatasetCampaign", campaign_id)
        if campaign.status != CampaignStatus.ACTIVE.value:
            raise DataMintException(
                detail=f"Campaign is not currently accepting submissions (status: {campaign.status})"
            )
        return campaign
