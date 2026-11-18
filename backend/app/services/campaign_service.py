"""Campaign creation, draft management, marketplace filtering, and funding boundary service."""

import hashlib
import uuid
from decimal import Decimal
from typing import List, Optional, Tuple, Union

from sqlalchemy import func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.config import settings
from app.core.exceptions import (
    DataMintException,
    EntityNotFoundException,
    InvalidStateTransitionException,
)
from app.models.campaign import CampaignRequirement, DatasetCampaign
from app.models.enums import CampaignStatus
from app.models.financial import EscrowCampaign
from app.schemas.campaign import (
    CampaignCreate,
    CampaignUpdateDraft,
    FundingParametersResponse,
)
from app.services.ledger_service import LedgerService


class CampaignService:
    def __init__(self, db: AsyncSession):
        self.db = db
        self.ledger_service = LedgerService(db)

    async def create_campaign(
        self, creator_id: uuid.UUID, data: Union[CampaignCreate, dict]
    ) -> DatasetCampaign:
        """Create a new dataset campaign in DRAFT state."""
        if isinstance(data, dict):
            data = CampaignCreate(**data)

        if isinstance(creator_id, str):
            creator_id = uuid.UUID(creator_id)

        campaign = DatasetCampaign(
            creator_id=creator_id,
            title=data.title,
            description=data.description,
            data_type=data.data_type.value,
            status=CampaignStatus.DRAFT.value,
            target_submissions=data.target_submissions,
            reward_per_submission=data.reward_per_submission,
            reward_currency=data.reward_currency,
            category=data.category,
            tags=data.tags,
            instructions=data.instructions,
            eligibility_criteria=data.eligibility_criteria,
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

    async def update_campaign_draft(
        self, campaign_id: uuid.UUID, creator_id: uuid.UUID, data: CampaignUpdateDraft
    ) -> DatasetCampaign:
        """Update draft campaign parameters. Term modifications are prohibited after activation."""
        campaign = await self.get_campaign(campaign_id)

        # Enforce creator ownership
        if campaign.creator_id != creator_id:
            raise DataMintException(
                detail="Only the campaign creator can modify this campaign draft",
                code="UNAUTHORIZED_CREATOR",
            )

        # Immutability check
        if campaign.status != CampaignStatus.DRAFT.value:
            raise DataMintException(
                detail=f"Campaign terms are immutable once submitted for funding or active (current status: {campaign.status})",
                code="CAMPAIGN_IMMUTABLE",
            )

        if data.title is not None:
            campaign.title = data.title
        if data.description is not None:
            campaign.description = data.description
        if data.data_type is not None:
            campaign.data_type = data.data_type.value
        if data.target_submissions is not None:
            campaign.target_submissions = data.target_submissions
        if data.reward_per_submission is not None:
            campaign.reward_per_submission = data.reward_per_submission
        if data.category is not None:
            campaign.category = data.category
        if data.tags is not None:
            campaign.tags = data.tags
        if data.instructions is not None:
            campaign.instructions = data.instructions
        if data.eligibility_criteria is not None:
            campaign.eligibility_criteria = data.eligibility_criteria
        if data.deadline is not None:
            campaign.deadline = data.deadline

        if data.requirements:
            if not campaign.requirements:
                campaign.requirements = CampaignRequirement(campaign_id=campaign.id)
                self.db.add(campaign.requirements)

            if data.requirements.min_duration_sec is not None:
                campaign.requirements.min_duration_sec = data.requirements.min_duration_sec
            if data.requirements.max_duration_sec is not None:
                campaign.requirements.max_duration_sec = data.requirements.max_duration_sec
            if data.requirements.instructions is not None:
                campaign.requirements.instructions = data.requirements.instructions
            if data.requirements.validation_rules is not None:
                campaign.requirements.validation_rules = data.requirements.validation_rules
            if data.requirements.criteria_metadata is not None:
                campaign.requirements.criteria_metadata = data.requirements.criteria_metadata

        await self.db.flush()
        return await self.get_campaign(campaign.id)

    async def get_campaign(self, campaign_id: uuid.UUID) -> DatasetCampaign:
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

    async def submit_for_funding(
        self, campaign_id: uuid.UUID, creator_id: uuid.UUID
    ) -> FundingParametersResponse:
        """
        Transition campaign from DRAFT to PENDING_FUNDING and generate on-chain escrow parameters.
        The backend does NOT declare the campaign active until verified on-chain evidence is confirmed.
        """
        campaign = await self.get_campaign(campaign_id)

        if campaign.creator_id != creator_id:
            raise DataMintException(detail="Only the campaign creator can submit for funding")

        if campaign.status != CampaignStatus.DRAFT.value:
            raise InvalidStateTransitionException(
                campaign.status, CampaignStatus.PENDING_FUNDING.value
            )

        # Transition status
        campaign.status = CampaignStatus.PENDING_FUNDING.value
        await self.db.flush()

        # Compute on-chain 32-byte identifier and amounts in 18-decimal base units
        onchain_id_bytes = hashlib.sha256(str(campaign.id).encode()).hexdigest()
        onchain_campaign_id = "0x" + onchain_id_bytes

        reward_wei = int(campaign.reward_per_submission * Decimal("1e18"))
        required_budget_wei = int(
            campaign.reward_per_submission
            * Decimal(str(campaign.target_submissions))
            * Decimal("1e18")
        )

        metadata_digest = (
            "0x"
            + hashlib.sha256(
                f"{campaign.title}:{campaign.description}:{campaign.data_type}".encode()
            ).hexdigest()
        )

        return FundingParametersResponse(
            campaign_id=campaign.id,
            onchain_campaign_id=onchain_campaign_id,
            reward_per_submission_wei=str(reward_wei),
            target_submissions=campaign.target_submissions,
            required_budget_wei=str(required_budget_wei),
            required_budget_formatted=f"{campaign.target_submissions * campaign.reward_per_submission} {campaign.reward_currency}",
            reward_currency=campaign.reward_currency,
            contract_address=settings.ESCROW_CONTRACT_ADDRESS,
            metadata_hash=metadata_digest,
        )

    async def confirm_onchain_funding(
        self,
        campaign_id: uuid.UUID,
        onchain_campaign_id: str,
        amount: Decimal,
        tx_hash: str,
        log_index: int = 0,
    ) -> DatasetCampaign:
        """
        Integration boundary for Phase 4 blockchain event indexer.
        Transitions campaign to ACTIVE and logs deposit in double-entry financial ledger.
        """
        campaign = await self.get_campaign(campaign_id)

        required_funding = campaign.reward_per_submission * Decimal(
            str(campaign.target_submissions)
        )
        if amount < required_funding:
            raise DataMintException(
                detail=f"Deposited amount {amount} is less than required budget {required_funding}",
                code="INSUFFICIENT_ONCHAIN_FUNDING",
            )

        ref_id = f"celo:tx:{tx_hash}:{log_index}"
        await self.ledger_service.record_deposit(
            campaign_id=campaign.id,
            amount=amount,
            reference_id=ref_id,
            onchain_campaign_id=onchain_campaign_id,
        )

        campaign.status = CampaignStatus.ACTIVE.value
        await self.db.flush()
        return campaign

    async def activate_campaign(
        self, campaign_id: uuid.UUID, onchain_campaign_id: str
    ) -> DatasetCampaign:
        """Activate campaign after validating on-chain escrow funding exists."""
        campaign = await self.get_campaign(campaign_id)
        if not campaign.escrow or campaign.escrow.total_funded <= Decimal("0.00"):
            raise InvalidStateTransitionException(campaign.status, CampaignStatus.ACTIVE.value)
        campaign.status = CampaignStatus.ACTIVE.value
        if campaign.escrow:
            campaign.escrow.onchain_campaign_id = onchain_campaign_id
        await self.db.flush()
        return campaign

    async def list_marketplace_campaigns(
        self,
        search: Optional[str] = None,
        data_type: Optional[str] = None,
        category: Optional[str] = None,
        min_reward: Optional[Decimal] = None,
        max_reward: Optional[Decimal] = None,
        sort_by: str = "newest",
        page: int = 1,
        page_size: int = 20,
    ) -> Tuple[List[DatasetCampaign], int]:
        """Search and filter publicly discoverable active campaigns."""
        base_query = select(DatasetCampaign).where(
            DatasetCampaign.status == CampaignStatus.ACTIVE.value
        )

        if search:
            search_pattern = f"%{search.strip()}%"
            base_query = base_query.where(
                or_(
                    DatasetCampaign.title.ilike(search_pattern),
                    DatasetCampaign.description.ilike(search_pattern),
                )
            )

        if data_type:
            base_query = base_query.where(DatasetCampaign.data_type == data_type)

        if category:
            base_query = base_query.where(DatasetCampaign.category == category)

        if min_reward is not None:
            base_query = base_query.where(DatasetCampaign.reward_per_submission >= min_reward)

        if max_reward is not None:
            base_query = base_query.where(DatasetCampaign.reward_per_submission <= max_reward)

        # Count total
        count_query = select(func.count()).select_from(base_query.subquery())
        total = (await self.db.execute(count_query)).scalar_one()

        # Sorting
        if sort_by == "reward_high":
            base_query = base_query.order_by(DatasetCampaign.reward_per_submission.desc())
        elif sort_by == "reward_low":
            base_query = base_query.order_by(DatasetCampaign.reward_per_submission.asc())
        elif sort_by == "deadline":
            base_query = base_query.order_by(DatasetCampaign.deadline.asc().nullslast())
        else:
            base_query = base_query.order_by(DatasetCampaign.created_at.desc())

        items_query = (
            base_query.options(
                selectinload(DatasetCampaign.requirements),
                selectinload(DatasetCampaign.escrow),
            )
            .offset((page - 1) * page_size)
            .limit(page_size)
        )
        result = await self.db.execute(items_query)
        return list(result.scalars().all()), total

    async def list_creator_campaigns(
        self, creator_id: uuid.UUID, page: int = 1, page_size: int = 20
    ) -> Tuple[List[DatasetCampaign], int]:
        """List campaigns created by the authenticated creator across all statuses."""
        base_query = select(DatasetCampaign).where(DatasetCampaign.creator_id == creator_id)

        count_query = select(func.count()).select_from(base_query.subquery())
        total = (await self.db.execute(count_query)).scalar_one()

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
