"""Pydantic schemas for human review and appeals workflows."""

import uuid
from datetime import datetime
from decimal import Decimal
from typing import Any, Dict, Optional

from pydantic import BaseModel, ConfigDict, Field

from app.models.enums import ReviewDecision


class ReviewDecisionRequest(BaseModel):
    """Payload for a reviewer resolving a submission in the review queue."""

    decision: ReviewDecision
    notes: Optional[str] = Field(None, max_length=2000, description="Internal reviewer rationale")
    rejection_reason: Optional[str] = Field(
        None, max_length=1000, description="Feedback displayed to contributor if rejected"
    )


class ReviewResponse(BaseModel):
    """Response representing a completed human review."""

    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    submission_id: uuid.UUID
    reviewer_id: uuid.UUID
    review_type: str
    decision: str
    notes: Optional[str] = None
    rejection_reason: Optional[str] = None
    created_at: datetime


class ReviewQueueItemResponse(BaseModel):
    """Summary item in the human review queue."""

    submission_id: uuid.UUID
    campaign_id: uuid.UUID
    campaign_title: str
    data_type: str
    contributor_id: uuid.UUID
    status: str
    created_at: datetime
    latest_score: Optional[Decimal] = None
    validation_runs_count: int = 0
    findings_count: int = 0


class AppealCreateRequest(BaseModel):
    """Payload submitted by a contributor appealing a rejected submission."""

    reason: str = Field(..., min_length=10, max_length=2000, description="Reason for appeal")
    evidence: Optional[Dict[str, Any]] = Field(
        default=None, description="Optional supporting metadata or context"
    )


class AppealResolveRequest(BaseModel):
    """Payload submitted by a reviewer resolving an appeal."""

    decision: ReviewDecision
    reviewer_notes: Optional[str] = Field(
        None, max_length=2000, description="Notes on upholding or overturning the appeal"
    )


class AppealResponse(BaseModel):
    """Full detail of a contributor appeal."""

    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    submission_id: uuid.UUID
    contributor_id: uuid.UUID
    reason: str
    evidence: Optional[Dict[str, Any]] = None
    status: str
    reviewer_id: Optional[uuid.UUID] = None
    reviewer_notes: Optional[str] = None
    resolved_at: Optional[datetime] = None
    created_at: datetime
