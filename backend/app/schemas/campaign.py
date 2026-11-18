"""Campaign and requirement schemas."""

import uuid
from datetime import datetime
from decimal import Decimal
from typing import List, Optional
from pydantic import Field, field_validator
from app.models.enums import CampaignStatus, DataType
from app.schemas.common import BaseSchema


class CampaignRequirementCreate(BaseSchema):
    min_duration_sec: Optional[int] = Field(default=None, ge=1)
    max_duration_sec: Optional[int] = Field(default=None, le=600)
    instructions: Optional[str] = None
    validation_rules: Optional[dict] = None
    criteria_metadata: Optional[dict] = None


class CampaignRequirementResponse(CampaignRequirementCreate):
    id: uuid.UUID
    campaign_id: uuid.UUID


class CampaignCreate(BaseSchema):
    title: str = Field(..., min_length=5, max_length=200)
    description: str = Field(..., min_length=10)
    data_type: DataType = Field(default=DataType.TEXT)
    target_submissions: int = Field(..., gt=0)
    reward_per_submission: Decimal = Field(..., gt=Decimal("0.0"))
    reward_currency: str = Field(default="cUSD")
    category: Optional[str] = Field(default=None, max_length=100)
    tags: Optional[List[str]] = None
    instructions: Optional[str] = None
    eligibility_criteria: Optional[dict] = None
    deadline: Optional[datetime] = None
    requirements: Optional[CampaignRequirementCreate] = None

    @field_validator("reward_per_submission")
    @classmethod
    def validate_reward(cls, v: Decimal) -> Decimal:
        if v <= 0:
            raise ValueError("Reward per submission must be greater than 0")
        return v


class CampaignUpdateDraft(BaseSchema):
    title: Optional[str] = Field(default=None, min_length=5, max_length=200)
    description: Optional[str] = Field(default=None, min_length=10)
    data_type: Optional[DataType] = None
    target_submissions: Optional[int] = Field(default=None, gt=0)
    reward_per_submission: Optional[Decimal] = Field(default=None, gt=Decimal("0.0"))
    category: Optional[str] = None
    tags: Optional[List[str]] = None
    instructions: Optional[str] = None
    eligibility_criteria: Optional[dict] = None
    deadline: Optional[datetime] = None
    requirements: Optional[CampaignRequirementCreate] = None


class EscrowSummaryResponse(BaseSchema):
    total_funded: Decimal
    total_claimed: Decimal
    total_reserved: Decimal
    total_available: Decimal
    total_refunded: Decimal
    onchain_campaign_id: Optional[str] = None


class CampaignResponse(BaseSchema):
    id: uuid.UUID
    creator_id: uuid.UUID
    title: str
    description: str
    data_type: str
    status: CampaignStatus
    target_submissions: int
    current_submissions: int
    reward_per_submission: Decimal
    reward_currency: str
    category: Optional[str] = None
    tags: Optional[List[str]] = None
    instructions: Optional[str] = None
    eligibility_criteria: Optional[dict] = None
    deadline: Optional[datetime] = None
    created_at: datetime
    updated_at: datetime
    requirements: Optional[CampaignRequirementResponse] = None
    escrow: Optional[EscrowSummaryResponse] = None


class FundingParametersResponse(BaseSchema):
    campaign_id: uuid.UUID
    onchain_campaign_id: str
    reward_per_submission_wei: str
    target_submissions: int
    required_budget_wei: str
    required_budget_formatted: str
    reward_currency: str
    contract_address: str
    metadata_hash: str
