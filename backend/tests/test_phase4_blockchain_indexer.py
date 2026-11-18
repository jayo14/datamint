"""Tests for blockchain event indexing, deduplication, and financial reconciliation."""

import secrets
from decimal import Decimal
from typing import Any, Dict, List, Optional

import pytest
from eth_account import Account
from sqlalchemy import select

from app.models.enums import (
    BlockchainEventStatus,
    CampaignStatus,
    DataType,
    PayoutStatus,
    SubmissionStatus,
)
from app.models.financial import BlockchainEvent
from app.models.identity import User
from app.models.notification import Notification
from app.models.wallet import Wallet
from app.schemas.campaign import CampaignCreate
from app.schemas.submission import SubmissionDraftCreate
from app.services.blockchain_indexer import (
    TOPIC_CAMPAIGN_CANCELLED,
    TOPIC_REWARD_CLAIMED,
    BlockchainIndexerService,
)
from app.services.campaign_service import CampaignService
from app.services.ledger_service import LedgerService
from app.services.payout_signer import LocalSignerProvider, PayoutSignerService
from app.services.reconciliation_service import ReconciliationService
from app.services.submission_service import SubmissionService


class MockBlockchainRpcClient:
    """Mock RPC client providing deterministic block numbers and log events."""

    def __init__(self, latest_block: int = 1000):
        self.latest_block = latest_block
        self.logs: List[Dict[str, Any]] = []
        self.block_hashes: Dict[int, str] = {}

    async def get_latest_block_number(self) -> int:
        return self.latest_block

    async def get_block_by_number(self, block_number: int) -> Optional[Dict[str, Any]]:
        block_hash = self.block_hashes.get(block_number, f"0x{block_number:064x}")
        return {"number": hex(block_number), "hash": block_hash}

    async def get_logs(
        self,
        from_block: int,
        to_block: int,
        address: str,
        topics: Optional[List[Optional[str]]] = None,
    ) -> List[Dict[str, Any]]:
        # Return logs that fall within block range
        return [log for log in self.logs if from_block <= int(log["blockNumber"], 16) <= to_block]


@pytest.mark.asyncio
async def test_indexer_campaign_funded_and_reward_claimed_settlement(db_session):
    """Test indexing CampaignFunded and RewardClaimed events and verifying ledger settlement."""
    campaign_service = CampaignService(db_session)
    submission_service = SubmissionService(db_session)
    ledger_service = LedgerService(db_session)

    # 1. Setup campaign & users
    creator = User(email="creator_idx@datamint.ai")
    contributor = User(email="contrib_idx@datamint.ai")
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
            title="Satellite Imagery Dataset",
            description="Label cloud formations",
            data_type=DataType.IMAGE,
            target_submissions=10,
            reward_per_submission=Decimal("4.00"),
        ),
    )
    onchain_cam_id = "0x" + "7" * 64
    campaign.escrow.onchain_campaign_id = onchain_cam_id
    campaign.escrow.total_funded = Decimal("40.00")
    campaign.escrow.total_available = Decimal("40.00")
    await campaign_service.activate_campaign(campaign.id, onchain_cam_id)
    await db_session.flush()

    # 2. Contributor submission & payout voucher generation
    sub = await submission_service.create_draft(
        contributor_id=contributor.id,
        data=SubmissionDraftCreate(
            campaign_id=campaign.id,
            draft_data={"clouds": "cumulus"},
        ),
    )
    sub.status = SubmissionStatus.APPROVED.value
    await db_session.flush()

    test_signer = Account.create()
    signer_provider = LocalSignerProvider(
        private_key=test_signer.key.hex(),
        contract_address="0x" + "1" * 40,
        chain_id=42220,
    )
    payout_service = PayoutSignerService(
        db=db_session,
        ledger_service=ledger_service,
        signer_provider=signer_provider,
    )
    payout = await payout_service.generate_payout_voucher(sub.id)
    assert payout.status == PayoutStatus.AUTHORIZED.value

    # Ledger state: 4.00 reserved, 36.00 available
    escrow = await ledger_service.get_escrow(campaign.id)
    assert escrow.total_reserved == Decimal("4.00")
    assert escrow.total_available == Decimal("36.00")

    # 3. Simulate on-chain RewardClaimed event
    tx_hash = "0x" + "f" * 64
    amount_wei_hex = hex(int(Decimal("4.00") * Decimal(10**18)))[2:].zfill(64)
    voucher_hash_hex = payout.voucher_hash[2:].zfill(64)
    simulated_data = "0x" + amount_wei_hex + voucher_hash_hex

    mock_client = MockBlockchainRpcClient(latest_block=150)
    mock_client.block_hashes[140] = "0x" + "8" * 64
    mock_client.logs.append(
        {
            "transactionHash": tx_hash,
            "logIndex": "0x1",
            "blockNumber": hex(140),
            "blockHash": "0x" + "8" * 64,
            "topics": [
                TOPIC_REWARD_CLAIMED,
                onchain_cam_id,
                "0x" + contrib_acc.address[2:].lower().zfill(64),
                payout.nonce,
            ],
            "data": simulated_data,
        }
    )

    # 4. Run indexer
    indexer = BlockchainIndexerService(
        db=db_session,
        ledger_service=ledger_service,
        rpc_client=mock_client,
        confirmation_depth=5,
    )
    indexed_count, last_block = await indexer.sync_events()
    assert indexed_count == 1
    assert last_block == 145

    # 5. Verify PayoutAuthorization and Submission transitioned to CLAIMED/SETTLED
    await db_session.refresh(payout)
    await db_session.refresh(sub)
    assert payout.status == PayoutStatus.CLAIMED.value
    assert payout.claim_tx_hash == tx_hash
    assert sub.status == SubmissionStatus.SETTLED.value

    # 6. Verify ledger state transition: 4.00 moved from reserved to claimed
    escrow_after = await ledger_service.get_escrow(campaign.id)
    assert escrow_after.total_reserved == Decimal("0.00")
    assert escrow_after.total_claimed == Decimal("4.00")
    assert escrow_after.total_available == Decimal("36.00")
    assert escrow_after.check_invariant() is True

    # 7. Deduplication check: running sync again produces 0 new events
    count_second, _ = await indexer.sync_events()
    assert count_second == 0


@pytest.mark.asyncio
async def test_reconciliation_service_detects_clean_and_discrepant_states(db_session):
    """Test that ReconciliationService properly audits escrow invariant and flags mismatches."""
    campaign_service = CampaignService(db_session)
    ledger_service = LedgerService(db_session)
    reconciliation_service = ReconciliationService(db_session, ledger_service=ledger_service)

    creator = User(email="creator_recon@datamint.ai")
    db_session.add(creator)
    await db_session.flush()

    campaign = await campaign_service.create_campaign(
        creator_id=creator.id,
        data=CampaignCreate(
            title="Clean Campaign",
            description="Test audit",
            data_type=DataType.TEXT,
            target_submissions=5,
            reward_per_submission=Decimal("1.00"),
        ),
    )
    # Record deposit via double-entry ledger
    await ledger_service.record_deposit(
        campaign_id=campaign.id,
        amount=Decimal("5.00"),
        reference_id=f"init_dep_{campaign.id}",
        onchain_campaign_id="0x" + "9" * 64,
    )
    await campaign_service.activate_campaign(campaign.id, "0x" + "9" * 64)
    await db_session.flush()

    # 1. Clean state reconciliation
    report_clean = await reconciliation_service.reconcile_campaign(campaign.id)
    assert report_clean.is_reconciled is True
    assert report_clean.invariant_holds is True
    assert len(report_clean.discrepancies) == 0

    # 2. Flag on-chain discrepancy
    report_onchain_diff = await reconciliation_service.reconcile_campaign(
        campaign.id,
        onchain_claimed_override=Decimal("10.00"),  # Mismatch with ledger 0.00
    )
    assert report_onchain_diff.is_reconciled is False
    assert len(report_onchain_diff.discrepancies) > 0
    assert "On-chain mismatch" in report_onchain_diff.discrepancies[0]


@pytest.mark.asyncio
async def test_indexer_reorganization_detection_and_orphaned_event_compensation(db_session):
    """Verify that chain reorganizations are detected and orphaned financial events compensated."""
    campaign_service = CampaignService(db_session)
    submission_service = SubmissionService(db_session)
    ledger_service = LedgerService(db_session)

    creator = User(email="creator_reorg@datamint.ai")
    contributor = User(email="contrib_reorg@datamint.ai")
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
            title="Reorg Resilient Dataset",
            description="Testing chain reorganization rollback",
            data_type=DataType.TEXT,
            target_submissions=5,
            reward_per_submission=Decimal("2.00"),
        ),
    )
    onchain_cam_id = f"0x{secrets.token_hex(32)}"
    campaign.escrow.onchain_campaign_id = onchain_cam_id
    campaign.escrow.total_funded = Decimal("10.00")
    campaign.escrow.total_available = Decimal("10.00")
    await campaign_service.activate_campaign(campaign.id, onchain_cam_id)
    await db_session.flush()

    sub = await submission_service.create_draft(
        contributor_id=contributor.id,
        data=SubmissionDraftCreate(
            campaign_id=campaign.id,
            draft_data={"text": "contribution for reorg test"},
        ),
    )
    sub.status = SubmissionStatus.APPROVED.value
    await db_session.flush()

    test_signer = Account.create()
    signer_provider = LocalSignerProvider(
        private_key=test_signer.key.hex(),
        contract_address="0x" + "3" * 40,
        chain_id=42220,
    )
    payout_service = PayoutSignerService(
        db=db_session,
        ledger_service=ledger_service,
        signer_provider=signer_provider,
    )
    payout = await payout_service.generate_payout_voucher(sub.id)
    assert payout.status == PayoutStatus.AUTHORIZED.value

    # Simulate RewardClaimed on fork block 200 with hash 0xdead...
    tx_hash = "0x" + "e" * 64
    amount_wei_hex = hex(int(Decimal("2.00") * Decimal(10**18)))[2:].zfill(64)
    voucher_hash_hex = payout.voucher_hash[2:].zfill(64)
    simulated_data = "0x" + amount_wei_hex + voucher_hash_hex

    mock_client = MockBlockchainRpcClient(latest_block=220)
    mock_client.block_hashes[200] = "0x" + "dead" * 16
    mock_client.logs.append(
        {
            "transactionHash": tx_hash,
            "logIndex": "0x0",
            "blockNumber": hex(200),
            "blockHash": "0x" + "dead" * 16,
            "topics": [
                TOPIC_REWARD_CLAIMED,
                onchain_cam_id,
                "0x" + contrib_acc.address[2:].lower().zfill(64),
                payout.nonce,
            ],
            "data": simulated_data,
        }
    )

    indexer = BlockchainIndexerService(
        db=db_session,
        ledger_service=ledger_service,
        rpc_client=mock_client,
        confirmation_depth=5,
    )
    indexed_count, last_block = await indexer.sync_events()
    assert indexed_count == 1

    # Verify claim settlement occurred
    await db_session.refresh(payout)
    await db_session.refresh(sub)
    assert payout.status == PayoutStatus.CLAIMED.value
    assert sub.status == SubmissionStatus.SETTLED.value
    escrow = await ledger_service.get_escrow(campaign.id)
    assert escrow.total_claimed == Decimal("2.00")
    assert escrow.total_reserved == Decimal("0.00")

    # Now simulate a reorganization at block 200: canonical chain adopted hash 0xbeef...
    mock_client.block_hashes[200] = "0x" + "beef" * 16

    # Next sync trigger detects the reorg and rolls back the orphaned event
    reorg_occurred = await indexer.detect_and_handle_reorg()
    assert reorg_occurred is True

    # Verify event is marked ORPHANED
    event_query = select(BlockchainEvent).where(BlockchainEvent.transaction_hash == tx_hash)
    ev = (await db_session.execute(event_query)).scalar_one()
    assert ev.status == BlockchainEventStatus.ORPHANED.value

    # Verify payout authorization reverted to AUTHORIZED
    await db_session.refresh(payout)
    assert payout.status == PayoutStatus.AUTHORIZED.value
    assert payout.claim_tx_hash is None

    # Verify submission reverted to APPROVED
    await db_session.refresh(sub)
    assert sub.status == SubmissionStatus.APPROVED.value

    # Verify ledger compensated: 2.00 moved back to reserved
    escrow_after = await ledger_service.get_escrow(campaign.id)
    assert escrow_after.total_claimed == Decimal("0.00")
    assert escrow_after.total_reserved == Decimal("2.00")
    assert escrow_after.check_invariant() is True


@pytest.mark.asyncio
async def test_indexer_campaign_cancelled_event(db_session):
    """Verify that on-chain CampaignCancelled events update campaign status and notify creator."""
    campaign_service = CampaignService(db_session)
    ledger_service = LedgerService(db_session)

    creator = User(email="creator_cancel@datamint.ai")
    db_session.add(creator)
    await db_session.flush()

    campaign = await campaign_service.create_campaign(
        creator_id=creator.id,
        data=CampaignCreate(
            title="Cancelled Campaign",
            description="Testing cancellation event",
            data_type=DataType.TEXT,
            target_submissions=10,
            reward_per_submission=Decimal("1.00"),
        ),
    )
    onchain_cam_id = f"0x{secrets.token_hex(32)}"
    campaign.escrow.onchain_campaign_id = onchain_cam_id
    campaign.escrow.total_funded = Decimal("10.00")
    campaign.escrow.total_available = Decimal("10.00")
    await campaign_service.activate_campaign(campaign.id, onchain_cam_id)
    await db_session.flush()

    tx_hash = "0x" + "c" * 64
    mock_client = MockBlockchainRpcClient(latest_block=300)
    mock_client.block_hashes[250] = "0x" + "2" * 64
    mock_client.logs.append(
        {
            "transactionHash": tx_hash,
            "logIndex": "0x0",
            "blockNumber": hex(250),
            "blockHash": "0x" + "2" * 64,
            "topics": [
                TOPIC_CAMPAIGN_CANCELLED,
                onchain_cam_id,
                "0x" + "0" * 24 + "1" * 40,
            ],
            "data": "0x",
        }
    )

    indexer = BlockchainIndexerService(
        db=db_session,
        ledger_service=ledger_service,
        rpc_client=mock_client,
        confirmation_depth=5,
    )
    indexed_count, _ = await indexer.sync_events()
    assert indexed_count == 1

    await db_session.refresh(campaign)
    assert campaign.status == CampaignStatus.CANCELLED.value

    # Verify notification created for creator
    notif_query = select(Notification).where(
        Notification.user_id == creator.id,
        Notification.event_type == "CAMPAIGN_CANCELLED",
    )
    notif = (await db_session.execute(notif_query)).scalar_one_or_none()
    assert notif is not None
