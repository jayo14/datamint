"""Tests for background Celery worker tasks and transactional outbox processing."""

from datetime import datetime, timedelta, timezone
from decimal import Decimal

import pytest
from eth_account import Account

from app.models.enums import DataType, OutboxStatus, PayoutStatus, SubmissionStatus
from app.models.identity import User
from app.models.notification import OutboxEvent
from app.models.wallet import Wallet
from app.schemas.campaign import CampaignCreate
from app.schemas.submission import SubmissionDraftCreate
from app.services.campaign_service import CampaignService
from app.services.ledger_service import LedgerService
from app.services.payout_signer import LocalSignerProvider, PayoutSignerService
from app.services.submission_service import SubmissionService
from app.workers.tasks import (
    execute_dispatch_outbox_notifications,
    execute_expire_stale_authorizations,
)


@pytest.mark.asyncio
async def test_worker_expire_stale_authorizations(db_session, monkeypatch):
    """Test background task expiring past-deadline vouchers and unreserving funds."""
    campaign_service = CampaignService(db_session)
    submission_service = SubmissionService(db_session)
    ledger_service = LedgerService(db_session)

    creator = User(email="creator_worker@datamint.ai")
    contributor = User(email="contrib_worker@datamint.ai")
    db_session.add_all([creator, contributor])
    await db_session.flush()

    contrib_acc = Account.create()
    wallet = Wallet(
        user_id=contributor.id,
        address=contrib_acc.address.lower(),
        chain_id=42220,
        is_primary=True,
    )
    db_session.add(wallet)
    await db_session.flush()

    campaign = await campaign_service.create_campaign(
        creator_id=creator.id,
        data=CampaignCreate(
            title="Worker Expiration Test",
            description="Testing task expiration",
            data_type=DataType.TEXT,
            target_submissions=5,
            reward_per_submission=Decimal("2.50"),
        ),
    )
    await ledger_service.record_deposit(
        campaign_id=campaign.id,
        amount=Decimal("12.50"),
        reference_id=f"dep_{campaign.id}",
        onchain_campaign_id="0x" + "c" * 64,
    )
    await campaign_service.activate_campaign(campaign.id, "0x" + "c" * 64)
    await db_session.flush()

    sub = await submission_service.create_draft(
        contributor_id=contributor.id,
        data=SubmissionDraftCreate(
            campaign_id=campaign.id,
            draft_data={"text": "testing worker expiration"},
        ),
    )
    sub.status = SubmissionStatus.APPROVED.value
    await db_session.flush()

    test_signer = Account.create()
    signer_provider = LocalSignerProvider(
        private_key=test_signer.key.hex(),
        contract_address="0x" + "2" * 40,
        chain_id=42220,
    )
    payout_service = PayoutSignerService(
        db=db_session,
        ledger_service=ledger_service,
        signer_provider=signer_provider,
    )
    payout = await payout_service.generate_payout_voucher(sub.id)

    # Manually backdate expiration to simulate expired voucher
    payout.expires_at = datetime.now(timezone.utc) - timedelta(hours=1)
    await db_session.flush()

    # Monkeypatch AsyncSessionLocal in workers.tasks to use our test db_session
    class MockSessionContext:
        async def __aenter__(self):
            return db_session

        async def __aexit__(self, exc_type, exc_val, exc_tb):
            pass

    monkeypatch.setattr("app.workers.tasks.AsyncSessionLocal", lambda: MockSessionContext())

    # Run the worker task logic
    result = await execute_expire_stale_authorizations()
    assert result["expired_count"] >= 1

    await db_session.refresh(payout)
    assert payout.status == PayoutStatus.EXPIRED.value

    # Verify funds were returned from reserved to available
    escrow = await ledger_service.get_escrow(campaign.id)
    assert escrow.total_reserved == Decimal("0.00")
    assert escrow.total_available == Decimal("12.50")
    assert escrow.check_invariant() is True


@pytest.mark.asyncio
async def test_worker_dispatch_outbox_notifications(db_session, monkeypatch):
    """Test background task publishing pending outbox events."""
    event = OutboxEvent(
        topic="submission.validated",
        payload={"submission_id": "test-123", "outcome": "APPROVED"},
        status=OutboxStatus.PENDING.value,
    )
    db_session.add(event)
    await db_session.flush()

    class MockSessionContext:
        async def __aenter__(self):
            return db_session

        async def __aexit__(self, exc_type, exc_val, exc_tb):
            pass

    monkeypatch.setattr("app.workers.tasks.AsyncSessionLocal", lambda: MockSessionContext())

    result = await execute_dispatch_outbox_notifications(batch_size=10)
    assert result["dispatched_count"] >= 1

    await db_session.refresh(event)
    assert event.status == OutboxStatus.PUBLISHED.value
