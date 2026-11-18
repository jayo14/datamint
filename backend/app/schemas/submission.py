"""Submission and validation schemas."""

import uuid
from datetime import datetime
from decimal import Decimal
from typing import List, Optional
from pydantic import Field
from app.models.enums import AssetType, SubmissionStatus, ValidationStatus
from app.schemas.common import BaseSchema


class SubmissionCreate(BaseSchema):
    campaign_id: uuid.UUID
    asset_type: AssetType = Field(default=AssetType.AUDIO)
    mime_type: str = Field(..., min_length=3)
    byte_size: int = Field(..., gt=0)
    filename: str = Field(..., min_length=1)
    checksum_sha256: Optional[str] = None


class SubmissionInitResponse(BaseSchema):
    submission_id: uuid.UUID
    upload_url: str
    storage_key: str
    expires_at: datetime


class AssetResponse(BaseSchema):
    id: uuid.UUID
    asset_type: str
    storage_key: str
    byte_size: int
    mime_type: str
    checksum_sha256: Optional[str] = None
    created_at: datetime


class ValidationFindingResponse(BaseSchema):
    code: str
    severity: str
    message: str
    details: Optional[dict] = None


class ValidationRunResponse(BaseSchema):
    id: uuid.UUID
    validator_type: str
    status: ValidationStatus
    score: Optional[Decimal] = None
    completed_at: Optional[datetime] = None
    findings: List[ValidationFindingResponse] = []


class SubmissionResponse(BaseSchema):
    id: uuid.UUID
    campaign_id: uuid.UUID
    contributor_id: uuid.UUID
    status: SubmissionStatus
    attempt_number: int
    created_at: datetime
    updated_at: datetime
    assets: List[AssetResponse] = []
    validation_runs: List[ValidationRunResponse] = []
