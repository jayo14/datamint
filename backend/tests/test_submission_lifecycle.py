"""Test submission pipeline: initialization, upload completion, approval, and voucher minting."""

from decimal import Decimal

import pytest

from app.models.enums import (
    DataType,
    PayoutStatus,
    SubmissionStatus,
)
from app.models.identity import User
from app.models.wallet import Wallet
from app.schemas.campaign import CampaignCreate
from app.schemas.submission import SubmissionCreate
from app.services.campaign_service import CampaignService
from app.services.submission_service import SubmissionService


@pytest.mark.asyncio
async def test_full_submission_approval_and_voucher_flow(db_session):
    """
    Test full submission lifecycle:
    1. Active campaign funded with 50.00 cUSD (5 submissions @ 10.00 cUSD).
    2. Contributor with registered primary wallet initializes submission -> PENDING_UPLOAD.
    3. Upload complete signal -> QUEUED_FOR_VALIDATION.
    4. Validation pass -> APPROVED.
    5. Reward (10.00 cUSD) reserved in financial ledger:
       Available: 50.00 -> 40.00, Reserved: 0.00 -> 10.00.
    6. EIP-712 PayoutAuthorization voucher minted with status AUTHORIZED.
    """
    campaign_service = CampaignService(db_session)
    submission_service = SubmissionService(db_session)

    # 1. Setup creator & campaign
    creator = User()
    db_session.add(creator)
    await db_session.flush()

    c_data = CampaignCreate(
        title="High Reward Audio Dataset",
        description="Premium audio recordings for model training",
        data_type=DataType.VOICE,
        target_submissions=5,
        reward_per_submission=Decimal("10.00"),
    )
    campaign = await campaign_service.create_campaign(creator_id=creator.id, data=c_data)
    campaign.escrow.total_funded = Decimal("50.00")
    campaign.escrow.total_available = Decimal("50.00")
    await campaign_service.activate_campaign(
        campaign_id=campaign.id, onchain_campaign_id="audio_pool_01"
    )

    # 2. Setup contributor with wallet
    contributor = User()
    db_session.add(contributor)
    await db_session.flush()

    c_wallet = Wallet(
        user_id=contributor.id,
        address="0x1111222233334444555566667777888899990000",
        chain_id=42220,
        is_primary=True,
    )
    db_session.add(c_wallet)
    await db_session.flush()

    # 3. Contributor initializes submission
    s_data = SubmissionCreate(
        campaign_id=campaign.id,
        mime_type="audio/wav",
        byte_size=500000,
        filename="speech_sample.wav",
    )
    init_res = await submission_service.initialize_submission(
        contributor_id=contributor.id, data=s_data
    )
    assert init_res.submission_id is not None
    assert "https://storage.datamint.ai/" in init_res.upload_url

    # 4. Upload completion signal
    submission = await submission_service.complete_upload(init_res.submission_id)
    assert submission.status == SubmissionStatus.QUEUED_FOR_VALIDATION.value

    # 5. Validation approval and payout minting
    approved_sub, payout = await submission_service.approve_submission_and_authorize_payout(
        submission_id=submission.id,
        score=Decimal("0.98"),
    )

    assert approved_sub.status == SubmissionStatus.APPROVED.value
    assert payout.status == PayoutStatus.AUTHORIZED.value
    assert payout.amount == Decimal("10.00")
    assert payout.recipient_address == c_wallet.address
    assert payout.voucher_hash.startswith("0x")

    # Invariant and ledger verification
    assert campaign.escrow.total_funded == Decimal("50.00")
    assert campaign.escrow.total_available == Decimal("40.00")
    assert campaign.escrow.total_reserved == Decimal("10.00")
    assert campaign.escrow.check_invariant() is True
