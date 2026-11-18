"""Campaigns API endpoints."""

import uuid
from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession
from app.api.deps import get_current_user, require_capability
from app.core.database import get_db
from app.models.enums import CapabilityType
from app.models.identity import User
from app.schemas.campaign import CampaignCreate, CampaignResponse
from app.services.campaign_service import CampaignService

router = APIRouter(prefix="/campaigns", tags=["Campaigns"])


@router.post("/", response_model=CampaignResponse, status_code=status.HTTP_201_CREATED)
async def create_campaign(
    payload: CampaignCreate,
    current_user: User = Depends(require_capability(CapabilityType.CREATOR)),
    db: AsyncSession = Depends(get_db),
) -> CampaignResponse:
    """Create a new dataset campaign in DRAFT state. Requires CREATOR capability."""
    service = CampaignService(db)
    campaign = await service.create_campaign(creator_id=current_user.id, data=payload)
    await db.commit()
    return CampaignResponse.model_validate(campaign)


@router.get("/{campaign_id}", response_model=CampaignResponse, status_code=status.HTTP_200_OK)
async def get_campaign(
    campaign_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
) -> CampaignResponse:
    """Fetch campaign details by ID."""
    service = CampaignService(db)
    campaign = await service.get_campaign(campaign_id=campaign_id)
    return CampaignResponse.model_validate(campaign)
