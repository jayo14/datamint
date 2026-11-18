"""Submission upload and validation endpoints."""

import uuid

from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import require_capability
from app.core.database import get_db
from app.models.enums import CapabilityType
from app.models.identity import User
from app.schemas.submission import (
    SubmissionCreate,
    SubmissionInitResponse,
    SubmissionResponse,
)
from app.services.submission_service import SubmissionService

router = APIRouter(prefix="/submissions", tags=["Submissions"])


@router.post("/", response_model=SubmissionInitResponse, status_code=status.HTTP_201_CREATED)
async def initialize_submission(
    payload: SubmissionCreate,
    current_user: User = Depends(require_capability(CapabilityType.CONTRIBUTOR)),
    db: AsyncSession = Depends(get_db),
) -> SubmissionInitResponse:
    """Initialize submission and get pre-signed storage URL. Requires CONTRIBUTOR capability."""
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
    """Signal that direct asset upload to storage has finished."""
    service = SubmissionService(db)
    submission = await service.complete_upload(submission_id=submission_id)
    await db.commit()
    return SubmissionResponse.model_validate(submission)


@router.get("/{submission_id}", response_model=SubmissionResponse, status_code=status.HTTP_200_OK)
async def get_submission_details(
    submission_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
) -> SubmissionResponse:
    """Get submission details, status, and validation findings."""
    service = SubmissionService(db)
    submission = await service.get_submission(submission_id=submission_id)
    return SubmissionResponse.model_validate(submission)
