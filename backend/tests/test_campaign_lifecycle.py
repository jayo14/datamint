"""Test campaign lifecycle transitions and funding gate."""

from decimal import Decimal

import pytest

from app.core.exceptions import InvalidStateTransitionException
from app.models.enums import CampaignStatus, DataType
from app.models.identity import User
from app.schemas.campaign import CampaignCreate
from app.services.campaign_service import CampaignService


@pytest.mark.asyncio
async def test_campaign_activation_requires_funding(db_session):
    """Test that a campaign cannot transition from DRAFT to ACTIVE without on-chain deposit."""
    campaign_service = CampaignService(db_session)

    creator = User()
    db_session.add(creator)
    await db_session.flush()

    data = CampaignCreate(
        title="Unfunded Campaign",
        description="This campaign has not been funded on Celo",
        data_type=DataType.TEXT,
        target_submissions=100,
        reward_per_submission=Decimal("1.00"),
    )
    campaign = await campaign_service.create_campaign(creator_id=creator.id, data=data)
    assert campaign.status == CampaignStatus.DRAFT.value

    # Attempting to activate without deposit should fail
    with pytest.raises(InvalidStateTransitionException):
        await campaign_service.activate_campaign(
            campaign_id=campaign.id, onchain_campaign_id="unfunded_123"
        )

    # Deposit funds
    campaign.escrow.total_funded = Decimal("100.00")
    campaign.escrow.total_available = Decimal("100.00")

    # Now activation succeeds
    activated = await campaign_service.activate_campaign(
        campaign_id=campaign.id, onchain_campaign_id="funded_123"
    )
    assert activated.status == CampaignStatus.ACTIVE.value
    assert activated.escrow.onchain_campaign_id == "funded_123"
