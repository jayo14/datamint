"""Submission and asset lifecycle API endpoints."""

import math
import uuid
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query, Request, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user, require_capability
from app.core.database import get_db
from app.core.rate_limit import media_rate_limiter, submission_rate_limiter
from app.models.enums import CapabilityType
from app.models.identity import User
from app.schemas.common import PaginatedResponse
from app.schemas.submission import (
    AssetResponse,
    ConfirmUploadRequest,
    SubmissionCreate,
    SubmissionDraftCreate,
    SubmissionDraftUpdate,
    SubmissionInitResponse,
    SubmissionResponse,
    UploadUrlRequest,
)
from app.services.submission_service import SubmissionService

router = APIRouter(prefix="/submissions", tags=["Submissions"])


@router.post("/drafts", response_model=SubmissionResponse, status_code=status.HTTP_201_CREATED)
async def create_submission_draft(
    payload: SubmissionDraftCreate,
    request: Request,
    current_user: User = Depends(require_capability(CapabilityType.CONTRIBUTOR)),
    db: AsyncSession = Depends(get_db),
) -> SubmissionResponse:
    """Create a new submission in DRAFT state."""
    await submission_rate_limiter.check(request, key_prefix="submission:draft")
    service = SubmissionService(db)
    submission = await service.create_draft(contributor_id=current_user.id, data=payload)
    await db.commit()
    return SubmissionResponse.model_validate(submission)


@router.put(
    "/drafts/{submission_id}", response_model=SubmissionResponse, status_code=status.HTTP_200_OK
)
async def update_submission_draft(
    submission_id: uuid.UUID,
    payload: SubmissionDraftUpdate,
    current_user: User = Depends(require_capability(CapabilityType.CONTRIBUTOR)),
    db: AsyncSession = Depends(get_db),
) -> SubmissionResponse:
    """Update payload or metadata for a submission in DRAFT state."""
    service = SubmissionService(db)
    submission = await service.update_draft(
        submission_id=submission_id,
        contributor_id=current_user.id,
        data=payload,
    )
    await db.commit()
    return SubmissionResponse.model_validate(submission)


@router.post(
    "/drafts/{submission_id}/upload-url",
    response_model=SubmissionInitResponse,
    status_code=status.HTTP_200_OK,
)
async def request_media_upload_url(
    submission_id: uuid.UUID,
    payload: UploadUrlRequest,
    request: Request,
    current_user: User = Depends(require_capability(CapabilityType.CONTRIBUTOR)),
    db: AsyncSession = Depends(get_db),
) -> SubmissionInitResponse:
    """Authorize asset upload and generate short-lived presigned upload URL."""
    await media_rate_limiter.check(request, key_prefix="media:upload")
    service = SubmissionService(db)
    res = await service.request_upload_url(
        submission_id=submission_id,
        contributor_id=current_user.id,
        filename=payload.filename,
        mime_type=payload.mime_type,
        byte_size=payload.byte_size,
        asset_type=payload.asset_type,
        checksum_sha256=payload.checksum_sha256,
    )
    await db.commit()
    return res


@router.post(
    "/drafts/{submission_id}/confirm-upload",
    response_model=AssetResponse,
    status_code=status.HTTP_200_OK,
)
async def confirm_media_upload(
    submission_id: uuid.UUID,
    payload: ConfirmUploadRequest,
    current_user: User = Depends(require_capability(CapabilityType.CONTRIBUTOR)),
    db: AsyncSession = Depends(get_db),
) -> AssetResponse:
    """Confirm asset upload to storage and mark asset as verified."""
    service = SubmissionService(db)
    asset = await service.confirm_upload(
        submission_id=submission_id,
        contributor_id=current_user.id,
        asset_id=payload.asset_id,
    )
    await db.commit()
    return AssetResponse.model_validate(asset)


@router.post(
    "/drafts/{submission_id}/submit",
    response_model=SubmissionResponse,
    status_code=status.HTTP_200_OK,
)
async def submit_for_validation(
    submission_id: uuid.UUID,
    request: Request,
    current_user: User = Depends(require_capability(CapabilityType.CONTRIBUTOR)),
    db: AsyncSession = Depends(get_db),
) -> SubmissionResponse:
    """Finalize submission with concurrency-safe capacity check and queue for validation."""
    await submission_rate_limiter.check(request, key_prefix="submission:finalize")
    service = SubmissionService(db)
    submission = await service.submit_for_validation(
        submission_id=submission_id,
        contributor_id=current_user.id,
    )
    await db.commit()
    return SubmissionResponse.model_validate(submission)


@router.get(
    "/my-submissions",
    response_model=PaginatedResponse[SubmissionResponse],
    status_code=status.HTTP_200_OK,
)
async def list_my_submissions(
    campaign_id: Optional[uuid.UUID] = Query(None, description="Filter by campaign"),
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    current_user: User = Depends(require_capability(CapabilityType.CONTRIBUTOR)),
    db: AsyncSession = Depends(get_db),
) -> PaginatedResponse[SubmissionResponse]:
    """List submissions created by the authenticated contributor."""
    service = SubmissionService(db)
    items, total = await service.list_contributor_submissions(
        contributor_id=current_user.id,
        campaign_id=campaign_id,
        page=page,
        page_size=page_size,
    )
    total_pages = math.ceil(total / page_size) if total > 0 else 1

    return PaginatedResponse[SubmissionResponse](
        items=[SubmissionResponse.model_validate(s) for s in items],
        total=total,
        page=page,
        page_size=page_size,
        total_pages=total_pages,
    )


@router.get(
    "/campaigns/{campaign_id}",
    response_model=PaginatedResponse[SubmissionResponse],
    status_code=status.HTTP_200_OK,
)
async def list_campaign_submissions(
    campaign_id: uuid.UUID,
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    current_user: User = Depends(require_capability(CapabilityType.CREATOR)),
    db: AsyncSession = Depends(get_db),
) -> PaginatedResponse[SubmissionResponse]:
    """List all submissions for a campaign. Caller must be the campaign creator."""
    service = SubmissionService(db)
    items, total = await service.list_campaign_submissions(
        campaign_id=campaign_id,
        creator_id=current_user.id,
        page=page,
        page_size=page_size,
    )
    total_pages = math.ceil(total / page_size) if total > 0 else 1

    return PaginatedResponse[SubmissionResponse](
        items=[SubmissionResponse.model_validate(s) for s in items],
        total=total,
        page=page,
        page_size=page_size,
        total_pages=total_pages,
    )


# Legacy endpoints maintained for backward compatibility
@router.post("/", response_model=SubmissionInitResponse, status_code=status.HTTP_201_CREATED)
async def initialize_submission(
    payload: SubmissionCreate,
    current_user: User = Depends(require_capability(CapabilityType.CONTRIBUTOR)),
    db: AsyncSession = Depends(get_db),
) -> SubmissionInitResponse:
    """Legacy submission initialization endpoint."""
    service = SubmissionService(db)
    init_res = await service.initialize_submission(contributor_id=current_user.id, data=payload)
    await db.commit()
    return init_res


@router.post(
    "/{submission_id}/complete", response_model=SubmissionResponse, status_code=status.HTTP_200_OK
)
async def complete_submission_upload(
    submission_id: uuid.UUID,
    current_user: User = Depends(require_capability(CapabilityType.CONTRIBUTOR)),
    db: AsyncSession = Depends(get_db),
) -> SubmissionResponse:
    """Legacy upload completion endpoint."""
    service = SubmissionService(db)
    submission = await service.complete_upload(
        submission_id=submission_id,
        contributor_id=current_user.id,
    )
    await db.commit()
    return SubmissionResponse.model_validate(submission)


@router.get("/{submission_id}", response_model=SubmissionResponse, status_code=status.HTTP_200_OK)
async def get_submission_details(
    submission_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> SubmissionResponse:
    """Get submission details, status, and validation findings. Access restricted to author, campaign creator, or reviewers."""
    service = SubmissionService(db)
    submission = await service.get_submission(submission_id=submission_id)

    user_caps = {c.capability_type for c in current_user.capabilities if c.is_enabled}
    is_owner = submission.contributor_id == current_user.id
    is_creator = submission.campaign is not None and submission.campaign.creator_id == current_user.id
    is_authorized_role = bool(user_caps.intersection({CapabilityType.REVIEWER.value, CapabilityType.ADMIN.value}))

    if not (is_owner or is_creator or is_authorized_role):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access forbidden: You do not have permission to view this submission.",
        )

    return SubmissionResponse.model_validate(submission)
