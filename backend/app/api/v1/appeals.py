"""Contributor appeals API endpoints."""

import uuid

from fastapi import APIRouter, Depends, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user, require_capability
from app.core.database import get_db
from app.core.exceptions import EntityNotFoundException
from app.models.enums import CapabilityType
from app.models.identity import User
from app.models.submission import Appeal
from app.schemas.review import AppealCreateRequest, AppealResolveRequest, AppealResponse
from app.services.review_service import ReviewService

router = APIRouter(prefix="/appeals", tags=["Contributor Appeals"])


@router.post(
    "/submissions/{submission_id}",
    response_model=AppealResponse,
    status_code=status.HTTP_201_CREATED,
)
async def submit_appeal(
    submission_id: uuid.UUID,
    payload: AppealCreateRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> AppealResponse:
    """Submit an appeal against an unfair or incorrect submission rejection."""
    service = ReviewService(db)
    appeal = await service.submit_appeal(
        submission_id=submission_id,
        contributor_id=current_user.id,
        request=payload,
    )
    await db.commit()
    return AppealResponse.model_validate(appeal)


@router.get(
    "/submissions/{submission_id}", response_model=AppealResponse, status_code=status.HTTP_200_OK
)
async def get_submission_appeal(
    submission_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> AppealResponse:
    """Retrieve the latest appeal for a submission."""
    query = (
        select(Appeal)
        .where(Appeal.submission_id == submission_id)
        .order_by(Appeal.created_at.desc())
    )
    appeal = (await db.execute(query)).scalars().first()
    if not appeal:
        raise EntityNotFoundException("Appeal for Submission", submission_id)
    return AppealResponse.model_validate(appeal)


@router.post("/{appeal_id}/resolve", response_model=AppealResponse, status_code=status.HTTP_200_OK)
async def resolve_appeal(
    appeal_id: uuid.UUID,
    payload: AppealResolveRequest,
    current_user: User = Depends(require_capability(CapabilityType.REVIEWER)),
    db: AsyncSession = Depends(get_db),
) -> AppealResponse:
    """Resolve a contributor appeal (APPROVED overturns rejection, REJECTED upholds)."""
    service = ReviewService(db)
    appeal = await service.resolve_appeal(
        appeal_id=appeal_id,
        reviewer_id=current_user.id,
        request=payload,
    )
    await db.commit()
    return AppealResponse.model_validate(appeal)
