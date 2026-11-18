"""Resilience, fault-tolerance, and disaster recovery tests for Phase 6."""

from datetime import datetime, timedelta, timezone
from decimal import Decimal
from unittest.mock import AsyncMock, MagicMock, patch
import uuid

import pytest
from httpx import AsyncClient

from app.core.config import settings
from app.core.exceptions import DomainRuleViolationException
from app.models.campaign import DatasetCampaign
from app.models.enums import BlockchainEventStatus, DataType, PayoutStatus, SubmissionStatus
from app.models.financial import BlockchainEvent, EscrowCampaign, LedgerEntry, PayoutAuthorization
from app.models.identity import User
from app.models.submission import Submission
from app.schemas.reconciliation import ReconciliationReport
from app.services.blockchain_indexer import BlockchainIndexerService
from app.services.payout_signer import PayoutSignerService
from app.services.reconciliation_service import ReconciliationService


class MockRpcClient:
    def __init__(self, logs=None, latest_block=1000):
        self.logs = logs or []
        self.latest_block = latest_block

    async def get_latest_block_number(self) -> int:
        return self.latest_block

    async def get_logs(self, from_block: int, to_block: int, address: str):
        return self.logs

    async def get_block_by_number(self, block_number: int):
        return {"hash": "0x" + "1" * 64, "number": block_number}


@pytest.mark.asyncio
async def test_duplicate_blockchain_event_idempotency(db_session):
    """Verify that duplicate blockchain events are idempotently ignored without double-crediting."""
    tx_hash = "0x" + "a" * 64
    raw_log = {
        "transactionHash": tx_hash,
        "logIndex": 0,
        "blockNumber": 100,
        "blockHash": "0x" + "1" * 64,
        "topics": ["0x" + "9" * 64],  # Unknown or custom topic
        "data": "0x",
    }

    mock_rpc = MockRpcClient(logs=[raw_log, raw_log], latest_block=120)
    indexer = BlockchainIndexerService(db_session, rpc_client=mock_rpc)

    # First sync processes the log
    indexed_1, _ = await indexer.sync_events(override_to_block=110)
    assert indexed_1 == 1

    # Second sync attempts to re-index the exact same log
    indexed_2, _ = await indexer.sync_events(override_to_block=110)
    assert indexed_2 == 0  # Idempotently discarded, not duplicated


@pytest.mark.asyncio
async def test_expired_payout_voucher_cleanup(db_session):
    """Verify that stale payout vouchers past their expiration deadline are identified and cleaned up."""
    creator = User(email="creator_payout_fail@datamint.ai")
    contributor = User(email="contrib_payout_fail@datamint.ai")
    db_session.add_all([creator, contributor])
    await db_session.flush()

    campaign = DatasetCampaign(
        creator_id=creator.id,
        title="Voucher Expiration Campaign",
        description="Testing voucher expiration resilience",
        instructions="Complete tasks",
        data_type=DataType.TEXT.value,
        reward_per_submission=Decimal("5.0"),
        target_submissions=10,
        status="ACTIVE",
    )
    db_session.add(campaign)
    await db_session.flush()

    escrow = EscrowCampaign(
        campaign_id=campaign.id,
        total_funded=Decimal("50.0"),
        total_available=Decimal("45.0"),
        total_reserved=Decimal("5.0"),
        total_claimed=Decimal("0.0"),
        total_refunded=Decimal("0.0"),
    )
    db_session.add(escrow)
    await db_session.flush()

    submission = Submission(
        campaign_id=campaign.id,
        contributor_id=contributor.id,
        status=SubmissionStatus.APPROVED.value,
    )
    db_session.add(submission)
    await db_session.flush()

    # Create an expired authorization (deadline in past)
    expired_auth = PayoutAuthorization(
        submission_id=submission.id,
        contributor_id=contributor.id,
        amount=Decimal("5.0"),
        recipient_address="0x" + "b" * 40,
        nonce="0x" + "1" * 64,
        onchain_campaign_id="0x" + "2" * 64,
        deadline=int((datetime.now(timezone.utc) - timedelta(hours=1)).timestamp()),
        voucher_hash="0x" + "d" * 64,
        signature="0x" + "c" * 130,
        status=PayoutStatus.AUTHORIZED.value,
        expires_at=datetime.now(timezone.utc) - timedelta(hours=1),
    )
    db_session.add(expired_auth)
    await db_session.commit()

    payout_service = PayoutSignerService(db_session)
    expired_res = await payout_service.expire_payout_voucher(expired_auth.id)
    await db_session.commit()

    assert expired_res.status == PayoutStatus.EXPIRED.value
    await db_session.refresh(escrow)
    assert escrow.total_reserved == Decimal("0.0")
    assert escrow.total_available == Decimal("50.0")


@pytest.mark.asyncio
async def test_reconciliation_detects_corrupted_invariants(db_session):
    """Verify that the financial reconciliation engine accurately catches and reports ledger-escrow discrepancy."""
    creator = User(email="creator_recon_fail@datamint.ai")
    db_session.add(creator)
    await db_session.flush()

    campaign = DatasetCampaign(
        creator_id=creator.id,
        title="Corrupted Ledger Campaign",
        description="Testing mathematical discrepancy detection",
        instructions="Do not manipulate rows",
        data_type=DataType.TEXT.value,
        reward_per_submission=Decimal("10.0"),
        target_submissions=5,
        status="ACTIVE",
    )
    db_session.add(campaign)
    await db_session.flush()

    # Corrupt total_funded deliberately to violate: total_funded == available + reserved + claimed + refunded
    escrow = EscrowCampaign(
        campaign_id=campaign.id,
        total_funded=Decimal("100.0"),  # Intentionally mismatching sum
        total_available=Decimal("20.0"),
        total_reserved=Decimal("0.0"),
        total_claimed=Decimal("0.0"),
        total_refunded=Decimal("0.0"),
    )
    db_session.add(escrow)
    await db_session.commit()

    recon_service = ReconciliationService(db_session)
    report: ReconciliationReport = await recon_service.reconcile_campaign(campaign.id)

    assert report.is_reconciled is False
    assert len(report.discrepancies) > 0
    assert any("Ledger invariant violation" in d for d in report.discrepancies)


@pytest.mark.asyncio
async def test_redis_unavailability_readiness_probe_handling(async_client: AsyncClient):
    """Verify that readiness probe handles Redis connection failures gracefully."""
    with patch("redis.asyncio.from_url") as mock_from_url:
        mock_redis = MagicMock()
        mock_redis.ping = AsyncMock(side_effect=ConnectionError("Redis cluster connection refused"))
        mock_from_url.return_value = mock_redis

        resp = await async_client.get("/api/v1/health/readyz")
        assert resp.status_code in (200, 503)
        data = resp.json()
        assert "redis" in data
        assert "unreachable" in data["redis"]
