"""Campaign creation, requirements management, and lifecycle state transitions."""

import uuid
from decimal import Decimal
from typing import List, Optional, Tuple
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload
from app.core.exceptions import (
    EntityNotFoundException,
    InvalidStateTransitionException,
)
from app.models.campaign import CampaignRequirement, DatasetCampaign
from app.models.enums import CampaignStatus
from app.models.financial import EscrowCampaign
from app.schemas.campaign import CampaignCreate


class CampaignService:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def create_campaign(
        self, creator_id: uuid.UUID, data: CampaignCreate
    ) -> DatasetCampaign:
        """Create a new dataset campaign in DRAFT state with requirements and escrow summary initialized."""
        campaign = DatasetCampaign(
            creator_id=creator_id,
            title=data.title,
            description=data.description,
            data_type=data.data_type.value,
            status=CampaignStatus.DRAFT.value,
            target_submissions=data.target_submissions,
            reward_per_submission=data.reward_per_submission,
            reward_currency=data.reward_currency,
            deadline=data.deadline,
        )
        self.db.add(campaign)
        await self.db.flush()

        # Initialize escrow summary
        escrow = EscrowCampaign(
            campaign_id=campaign.id,
            total_funded=Decimal("0.0"),
            total_available=Decimal("0.0"),
            total_reserved=Decimal("0.0"),
            total_claimed=Decimal("0.0"),
            total_refunded=Decimal("0.0"),
        )
        self.db.add(escrow)

        # Attach requirements if provided
        if data.requirements:
            req = CampaignRequirement(
                campaign_id=campaign.id,
                min_duration_sec=data.requirements.min_duration_sec,
                max_duration_sec=data.requirements.max_duration_sec,
                instructions=data.requirements.instructions,
                validation_rules=data.requirements.validation_rules,
                criteria_metadata=data.requirements.criteria_metadata,
            )
            self.db.add(req)

        await self.db.flush()
        return await self.get_campaign(campaign.id)

    async def get_campaign(self, campaign_id: uuid.UUID) -> DatasetCampaign:
        """Fetch campaign with requirements and escrow loaded."""
        query = (
            select(DatasetCampaign)
            .where(DatasetCampaign.id == campaign_id)
            .options(
                selectinload(DatasetCampaign.requirements),
                selectinload(DatasetCampaign.escrow),
            )
        )
        result = await self.db.execute(query)
        campaign = result.scalar_one_or_none()
        if not campaign:
            raise EntityNotFoundException("DatasetCampaign", campaign_id)
        return campaign

    async def list_marketplace_campaigns(
        self,
        data_type: Optional[str] = None,
        page: int = 1,
        page_size: int = 20,
    ) -> Tuple[List[DatasetCampaign], int]:
        """List active campaigns for contributor marketplace browsing."""
        base_query = select(DatasetCampaign).where(
            DatasetCampaign.status == CampaignStatus.ACTIVE.value
        )
        if data_type:
            base_query = base_query.where(DatasetCampaign.data_type == data_type)

        # Total count
        count_query = select(func.count()).select_from(base_query.subquery())
        total = (await self.db.execute(count_query)).scalar_one()

        # Paginated items
        items_query = (
            base_query.options(
                selectinload(DatasetCampaign.requirements),
                selectinload(DatasetCampaign.escrow),
            )
            .order_by(DatasetCampaign.created_at.desc())
            .offset((page - 1) * page_size)
            .limit(page_size)
        )
        result = await self.db.execute(items_query)
        return list(result.scalars().all()), total

    async def activate_campaign(
        self, campaign_id: uuid.UUID, onchain_campaign_id: str
    ) -> DatasetCampaign:
        """Activate campaign once escrow deposit is confirmed."""
        campaign = await self.get_campaign(campaign_id)

        if campaign.status not in (
            CampaignStatus.DRAFT.value,
            CampaignStatus.PENDING_FUNDING.value,
        ):
            raise InvalidStateTransitionException(campaign.status, CampaignStatus.ACTIVE.value)

        # Invariant check: escrow must have funded >= (target_submissions * reward_per_submission)
        required_min_funding = (
            Decimal(str(campaign.target_submissions)) * campaign.reward_per_submission
        )
        if not campaign.escrow or campaign.escrow.total_funded < required_min_funding:
            raise InvalidStateTransitionException(
                campaign.status,
                f"ACTIVE (insufficient deposit: funded {campaign.escrow.total_funded if campaign.escrow else 0} < required {required_min_funding})",
            )

        campaign.status = CampaignStatus.ACTIVE.value
        campaign.escrow.onchain_campaign_id = onchain_campaign_id
        await self.db.flush()
        return campaign
