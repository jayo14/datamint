"""Marketplace task discovery endpoints."""

import math
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
    data_type: Optional[str] = Query(None, description="Filter by data type (TEXT, VOICE, IMAGE)"),
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
) -> PaginatedResponse[CampaignResponse]:
    """Public marketplace discovery of open campaigns accepting contributions."""
    service = CampaignService(db)
    items, total = await service.list_marketplace_campaigns(
        data_type=data_type, page=page, page_size=page_size
    )
    total_pages = math.ceil(total / page_size) if total > 0 else 1

    return PaginatedResponse[CampaignResponse](
        items=[CampaignResponse.model_validate(c) for c in items],
        total=total,
        page=page,
        page_size=page_size,
        total_pages=total_pages,
    )
