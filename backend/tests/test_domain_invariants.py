"""Test suite verifying the financial ledger accounting invariant and non-destructive entries."""

from decimal import Decimal

import pytest

from app.core.exceptions import (
    InsufficientFundsException,
)
from app.models.campaign import DatasetCampaign
from app.models.enums import CampaignStatus, DataType
from app.models.financial import EscrowCampaign
from app.models.identity import User
from app.services.ledger_service import LedgerService


@pytest.mark.asyncio
async def test_financial_ledger_invariant_lifecycle(db_session):
    """
    Verify: Funded == Claimed + Reserved + Available + Refunded
    Through: Deposit -> Reserve -> Claim -> Refund
    """
    ledger_service = LedgerService(db_session)

    # 1. Create a user and campaign
    user = User()
    db_session.add(user)
    await db_session.flush()

    campaign = DatasetCampaign(
        creator_id=user.id,
        title="Voice Data Campaign",
        description="Dataset campaign description",
        data_type=DataType.VOICE.value,
        status=CampaignStatus.DRAFT.value,
        target_submissions=10,
        reward_per_submission=Decimal("1.50"),
    )
    db_session.add(campaign)
    await db_session.flush()

    escrow = EscrowCampaign(
        campaign_id=campaign.id,
        total_funded=Decimal("0.0"),
        total_available=Decimal("0.0"),
        total_reserved=Decimal("0.0"),
        total_claimed=Decimal("0.0"),
        total_refunded=Decimal("0.0"),
    )
    db_session.add(escrow)
    await db_session.flush()

    assert escrow.check_invariant() is True

    # 2. Deposit 15.00 cUSD
    deposit_entry = await ledger_service.record_deposit(
        campaign_id=campaign.id,
        amount=Decimal("15.00"),
        reference_id="celo:tx:0x123abc:0",
        onchain_campaign_id="101",
    )
    assert deposit_entry.running_available == Decimal("15.00")
    assert escrow.total_funded == Decimal("15.00")
    assert escrow.total_available == Decimal("15.00")
    assert escrow.check_invariant() is True

    # 3. Reserve 1.50 cUSD for approved submission
    reserve_entry = await ledger_service.reserve_payout(
        campaign_id=campaign.id,
        amount=Decimal("1.50"),
        reference_id="sub:reserve:001",
    )
    assert reserve_entry.running_available == Decimal("13.50")
    assert reserve_entry.running_reserved == Decimal("1.50")
    assert escrow.total_available == Decimal("13.50")
    assert escrow.total_reserved == Decimal("1.50")
    assert escrow.check_invariant() is True

    # 4. Claim 1.50 cUSD on-chain by contributor
    claim_entry = await ledger_service.record_claim(
        campaign_id=campaign.id,
        amount=Decimal("1.50"),
        reference_id="celo:claim:0x789def:0",
    )
    assert claim_entry.running_reserved == Decimal("0.0")
    assert claim_entry.running_claimed == Decimal("1.50")
    assert escrow.total_claimed == Decimal("1.50")
    assert escrow.check_invariant() is True

    # 5. Refund remaining 13.50 cUSD to creator
    refund_entry = await ledger_service.record_refund(
        campaign_id=campaign.id,
        amount=Decimal("13.50"),
        reference_id="celo:refund:0x999xyz",
    )
    assert refund_entry.running_available == Decimal("0.0")
    assert refund_entry.running_refunded == Decimal("13.50")
    assert escrow.total_available == Decimal("0.0")
    assert escrow.total_refunded == Decimal("13.50")
    assert escrow.check_invariant() is True

    # Final Invariant Check: 15.00 == 1.50 (claimed) + 0 (reserved) + 0 (available) + 13.50 (refunded)
    assert escrow.total_funded == (
        escrow.total_claimed
        + escrow.total_reserved
        + escrow.total_available
        + escrow.total_refunded
    )


@pytest.mark.asyncio
async def test_cannot_over_reserve_available_funds(db_session):
    """Test that attempting to reserve more funds than available raises InsufficientFundsException."""
    ledger_service = LedgerService(db_session)

    user = User()
    db_session.add(user)
    await db_session.flush()

    campaign = DatasetCampaign(
        creator_id=user.id,
        title="Test Campaign",
        description="Description",
        data_type=DataType.TEXT.value,
        target_submissions=5,
        reward_per_submission=Decimal("2.00"),
    )
    db_session.add(campaign)
    await db_session.flush()

    escrow = EscrowCampaign(
        campaign_id=campaign.id,
        total_funded=Decimal("5.00"),
        total_available=Decimal("5.00"),
    )
    db_session.add(escrow)
    await db_session.flush()

    # Attempt to reserve 10.00 when available is 5.00
    with pytest.raises(InsufficientFundsException):
        await ledger_service.reserve_payout(
            campaign_id=campaign.id,
            amount=Decimal("10.00"),
            reference_id="sub:reserve:overdraft",
        )


@pytest.mark.asyncio
async def test_ledger_idempotency_prevents_duplicate_entries(db_session):
    """Test that replaying a reference_id returns the existing entry and avoids double booking."""
    ledger_service = LedgerService(db_session)

    user = User()
    db_session.add(user)
    await db_session.flush()

    campaign = DatasetCampaign(
        creator_id=user.id,
        title="Idempotency Campaign",
        description="Description",
        data_type=DataType.TEXT.value,
        target_submissions=5,
        reward_per_submission=Decimal("1.00"),
    )
    db_session.add(campaign)
    await db_session.flush()

    escrow = EscrowCampaign(campaign_id=campaign.id)
    db_session.add(escrow)
    await db_session.flush()

    # First deposit
    ref_id = "celo:tx:0xreplayed:0"
    entry1 = await ledger_service.record_deposit(
        campaign_id=campaign.id,
        amount=Decimal("10.00"),
        reference_id=ref_id,
    )
    assert escrow.total_funded == Decimal("10.00")

    # Replay same deposit
    entry2 = await ledger_service.record_deposit(
        campaign_id=campaign.id,
        amount=Decimal("10.00"),
        reference_id=ref_id,
    )
    assert entry1.id == entry2.id
    # Total funded must NOT double to 20.00
    assert escrow.total_funded == Decimal("10.00")
