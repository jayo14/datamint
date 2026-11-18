"""Test verifying dual capabilities (contributor + creator) on a single user identity."""

from decimal import Decimal

import pytest

from app.models.enums import CapabilityType, DataType
from app.models.identity import User, UserCapability
from app.schemas.campaign import CampaignCreate
from app.schemas.submission import SubmissionCreate
from app.services.campaign_service import CampaignService
from app.services.submission_service import SubmissionService


@pytest.mark.asyncio
async def test_single_user_dual_capabilities(db_session):
    """
    Verify that one user can:
    1. Hold both CONTRIBUTOR and CREATOR capabilities.
    2. Act as a Creator by creating a dataset campaign.
    3. Act as a Contributor by submitting to another campaign.
    """
    campaign_service = CampaignService(db_session)
    submission_service = SubmissionService(db_session)

    # 1. Create a user with both capabilities
    user = User()
    db_session.add(user)
    await db_session.flush()

    cap_creator = UserCapability(
        user_id=user.id,
        capability_type=CapabilityType.CREATOR.value,
        is_enabled=True,
    )
    cap_contributor = UserCapability(
        user_id=user.id,
        capability_type=CapabilityType.CONTRIBUTOR.value,
        is_enabled=True,
    )
    db_session.add_all([cap_creator, cap_contributor])
    await db_session.flush()

    # Verify user capabilities
    user_caps = [c.capability_type for c in [cap_creator, cap_contributor]]
    assert CapabilityType.CREATOR.value in user_caps
    assert CapabilityType.CONTRIBUTOR.value in user_caps

    # 2. User acts as CREATOR: create campaign
    campaign_payload = CampaignCreate(
        title="Creator User Campaign",
        description="A campaign created by our multi-capability user",
        data_type=DataType.TEXT,
        target_submissions=10,
        reward_per_submission=Decimal("0.50"),
    )
    created_campaign = await campaign_service.create_campaign(
        creator_id=user.id, data=campaign_payload
    )
    assert created_campaign.creator_id == user.id

    # 3. User acts as CONTRIBUTOR: submit to another active campaign
    # Setup another creator and active campaign
    other_creator = User()
    db_session.add(other_creator)
    await db_session.flush()

    other_campaign_data = CampaignCreate(
        title="Other Campaign",
        description="Another dataset campaign accepting submissions",
        data_type=DataType.VOICE,
        target_submissions=20,
        reward_per_submission=Decimal("1.00"),
    )
    other_campaign = await campaign_service.create_campaign(
        creator_id=other_creator.id, data=other_campaign_data
    )
    # Fund and activate other campaign
    other_campaign.escrow.total_funded = Decimal("20.00")
    other_campaign.escrow.total_available = Decimal("20.00")
    await campaign_service.activate_campaign(
        campaign_id=other_campaign.id, onchain_campaign_id="test_onchain_99"
    )

    # Contributor action from original user
    submission_payload = SubmissionCreate(
        campaign_id=other_campaign.id,
        mime_type="audio/wav",
        byte_size=10240,
        filename="voice_sample.wav",
    )
    init_res = await submission_service.initialize_submission(
        contributor_id=user.id, data=submission_payload
    )

    assert init_res.submission_id is not None
    assert init_res.upload_url is not None
