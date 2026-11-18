"""Human review queue and evaluation API endpoints."""

import math
import uuid
from typing import Optional

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import require_capability
from app.core.database import get_db
from app.models.enums import CapabilityType
from app.models.identity import User
from app.schemas.common import PaginatedResponse
from app.schemas.review import (
    ReviewDecisionRequest,
    ReviewQueueItemResponse,
    ReviewResponse,
)
from app.schemas.submission import SubmissionResponse
from app.services.review_service import ReviewService

router = APIRouter(prefix="/reviews", tags=["Human Review"])


@router.get(
    "/queue",
    response_model=PaginatedResponse[ReviewQueueItemResponse],
    status_code=status.HTTP_200_OK,
)
async def get_review_queue(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    status_filter: Optional[str] = Query(
        None, description="Optional filter by status (NEEDS_REVIEW or UNDER_APPEAL)"
    ),
    current_user: User = Depends(require_capability(CapabilityType.REVIEWER)),
    db: AsyncSession = Depends(get_db),
) -> PaginatedResponse[ReviewQueueItemResponse]:
    """Retrieve submissions currently in queue awaiting manual reviewer evaluation."""
    service = ReviewService(db)
    items, total = await service.get_review_queue(
        page=page, page_size=page_size, status_filter=status_filter
    )
    total_pages = math.ceil(total / page_size) if total > 0 else 1
    return PaginatedResponse(
        items=items,
        total=total,
        page=page,
        page_size=page_size,
        total_pages=total_pages,
    )


@router.get(
    "/submissions/{submission_id}",
    response_model=SubmissionResponse,
    status_code=status.HTTP_200_OK,
)
async def get_submission_for_review(
    submission_id: uuid.UUID,
    current_user: User = Depends(require_capability(CapabilityType.REVIEWER)),
    db: AsyncSession = Depends(get_db),
) -> SubmissionResponse:
    """Fetch full submission context, AI validation runs, and findings for review."""
    service = ReviewService(db)
    submission = await service.get_submission_review_details(submission_id)
    return SubmissionResponse.model_validate(submission)


@router.post(
    "/submissions/{submission_id}/decide",
    response_model=ReviewResponse,
    status_code=status.HTTP_200_OK,
)
async def submit_review_decision(
    submission_id: uuid.UUID,
    payload: ReviewDecisionRequest,
    current_user: User = Depends(require_capability(CapabilityType.REVIEWER)),
    db: AsyncSession = Depends(get_db),
) -> ReviewResponse:
    """Submit human reviewer decision approving or rejecting a submission."""
    service = ReviewService(db)
    review = await service.submit_review_decision(
        submission_id=submission_id,
        reviewer_id=current_user.id,
        request=payload,
    )
    await db.commit()
    return ReviewResponse.model_validate(review)
