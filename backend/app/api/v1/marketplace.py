"""Marketplace task discovery endpoints."""

import math
from decimal import Decimal
from typing import Optional

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.schemas.campaign import CampaignResponse
from app.schemas.common import PaginatedResponse
from app.services.campaign_service import CampaignService

router = APIRouter(prefix="/marketplace", tags=["Marketplace"])


@router.get(
    "/tasks", response_model=PaginatedResponse[CampaignResponse], status_code=status.HTTP_200_OK
)
async def list_tasks(
    search: Optional[str] = Query(
        None, description="Keyword search in campaign title and description"
    ),
    data_type: Optional[str] = Query(None, description="Filter by data type (TEXT, VOICE, IMAGE)"),
    category: Optional[str] = Query(None, description="Filter by campaign category"),
    min_reward: Optional[Decimal] = Query(None, ge=0, description="Minimum reward per submission"),
    max_reward: Optional[Decimal] = Query(None, ge=0, description="Maximum reward per submission"),
    sort_by: str = Query(
        "newest", description="Sorting criteria: newest, reward_high, reward_low, deadline"
    ),
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
) -> PaginatedResponse[CampaignResponse]:
    """Public marketplace discovery of active campaigns accepting contributions."""
    service = CampaignService(db)
    items, total = await service.list_marketplace_campaigns(
        search=search,
        data_type=data_type,
        category=category,
        min_reward=min_reward,
        max_reward=max_reward,
        sort_by=sort_by,
        page=page,
        page_size=page_size,
    )
    total_pages = math.ceil(total / page_size) if total > 0 else 1

    return PaginatedResponse[CampaignResponse](
        items=[CampaignResponse.model_validate(c) for c in items],
        total=total,
        page=page,
        page_size=page_size,
        total_pages=total_pages,
    )
