"""Campaigns API endpoints."""

import math
import uuid

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import require_capability
from app.core.database import get_db
from app.models.enums import CapabilityType
from app.models.identity import User
from app.schemas.campaign import (
    CampaignCreate,
    CampaignResponse,
    CampaignUpdateDraft,
    FundingParametersResponse,
)
from app.schemas.common import PaginatedResponse
from app.services.campaign_service import CampaignService

router = APIRouter(prefix="/campaigns", tags=["Campaigns"])


@router.post("", response_model=CampaignResponse, status_code=status.HTTP_201_CREATED)
@router.post("/", response_model=CampaignResponse, status_code=status.HTTP_201_CREATED)
@router.post("/draft", response_model=CampaignResponse, status_code=status.HTTP_201_CREATED)
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


@router.put("/{campaign_id}", response_model=CampaignResponse, status_code=status.HTTP_200_OK)
@router.put("/drafts/{campaign_id}", response_model=CampaignResponse, status_code=status.HTTP_200_OK)
async def update_campaign_draft(
    campaign_id: uuid.UUID,
    payload: CampaignUpdateDraft,
    current_user: User = Depends(require_capability(CapabilityType.CREATOR)),
    db: AsyncSession = Depends(get_db),
) -> CampaignResponse:
    """Update editable fields of a campaign while it is in DRAFT state."""
    service = CampaignService(db)
    campaign = await service.update_campaign_draft(
        campaign_id=campaign_id,
        creator_id=current_user.id,
        data=payload,
    )
    await db.commit()
    return CampaignResponse.model_validate(campaign)


@router.post(
    "/{campaign_id}/submit-funding",
    response_model=FundingParametersResponse,
    status_code=status.HTTP_200_OK,
)
@router.post(
    "/{campaign_id}/publish",
    response_model=FundingParametersResponse,
    status_code=status.HTTP_200_OK,
)
@router.post(
    "/drafts/{campaign_id}/publish",
    response_model=FundingParametersResponse,
    status_code=status.HTTP_200_OK,
)
async def submit_campaign_for_funding(
    campaign_id: uuid.UUID,
    current_user: User = Depends(require_capability(CapabilityType.CREATOR)),
    db: AsyncSession = Depends(get_db),
) -> FundingParametersResponse:
    """Transition campaign to PENDING_FUNDING and return exact on-chain parameters for DatasetEscrow.createCampaign."""
    service = CampaignService(db)
    params = await service.submit_for_funding(
        campaign_id=campaign_id,
        creator_id=current_user.id,
    )
    await db.commit()
    return params


@router.get(
    "/my-campaigns",
    response_model=PaginatedResponse[CampaignResponse],
    status_code=status.HTTP_200_OK,
)
async def list_my_campaigns(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    current_user: User = Depends(require_capability(CapabilityType.CREATOR)),
    db: AsyncSession = Depends(get_db),
) -> PaginatedResponse[CampaignResponse]:
    """List all campaigns created by the authenticated creator across all statuses."""
    service = CampaignService(db)
    items, total = await service.list_creator_campaigns(
        creator_id=current_user.id, page=page, page_size=page_size
    )
    total_pages = math.ceil(total / page_size) if total > 0 else 1

    return PaginatedResponse[CampaignResponse](
        items=[CampaignResponse.model_validate(c) for c in items],
        total=total,
        page=page,
        page_size=page_size,
        total_pages=total_pages,
    )


@router.get("/{campaign_id}", response_model=CampaignResponse, status_code=status.HTTP_200_OK)
async def get_campaign(
    campaign_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
) -> CampaignResponse:
    """Fetch campaign details by ID."""
    service = CampaignService(db)
    campaign = await service.get_campaign(campaign_id=campaign_id)
    return CampaignResponse.model_validate(campaign)
