"""Reliable Celo blockchain event indexer tracking DatasetEscrow.sol on-chain activity."""

import logging
from datetime import datetime, timezone
from decimal import Decimal
from typing import Any, Dict, List, Optional, Protocol, Tuple, cast

import httpx
from eth_utils import keccak
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.config import settings
from app.models.enums import BlockchainEventStatus, CampaignStatus, PayoutStatus, SubmissionStatus
from app.models.financial import (
    BlockchainEvent,
    EscrowCampaign,
    IndexerSyncState,
    PayoutAuthorization,
)
from app.models.notification import Notification
from app.models.submission import Submission
from app.services.ledger_service import LedgerService

logger = logging.getLogger(__name__)

# Event Signatures and Topic0 hashes for DatasetEscrow.sol
EVENT_CAMPAIGN_CREATED_SIG = (
    "CampaignCreated(bytes32,address,uint256,uint256,uint256,uint256,bytes32)"
)
EVENT_CAMPAIGN_FUNDED_SIG = "CampaignFunded(bytes32,address,uint256,uint256)"
EVENT_CAMPAIGN_ACTIVATED_SIG = "CampaignActivated(bytes32,uint256)"
EVENT_REWARD_CLAIMED_SIG = "RewardClaimed(bytes32,address,uint256,bytes32,bytes32)"
EVENT_CAMPAIGN_REFUNDED_SIG = "CampaignRefunded(bytes32,address,uint256,uint256)"
EVENT_CAMPAIGN_CLOSED_SIG = "CampaignClosed(bytes32,uint256,uint256)"
EVENT_CAMPAIGN_CANCELLED_SIG = "CampaignCancelled(bytes32,address,string)"

TOPIC_CAMPAIGN_CREATED = "0x" + keccak(text=EVENT_CAMPAIGN_CREATED_SIG).hex()
TOPIC_CAMPAIGN_FUNDED = "0x" + keccak(text=EVENT_CAMPAIGN_FUNDED_SIG).hex()
TOPIC_CAMPAIGN_ACTIVATED = "0x" + keccak(text=EVENT_CAMPAIGN_ACTIVATED_SIG).hex()
TOPIC_REWARD_CLAIMED = "0x" + keccak(text=EVENT_REWARD_CLAIMED_SIG).hex()
TOPIC_CAMPAIGN_REFUNDED = "0x" + keccak(text=EVENT_CAMPAIGN_REFUNDED_SIG).hex()
TOPIC_CAMPAIGN_CLOSED = "0x" + keccak(text=EVENT_CAMPAIGN_CLOSED_SIG).hex()
TOPIC_CAMPAIGN_CANCELLED = "0x" + keccak(text=EVENT_CAMPAIGN_CANCELLED_SIG).hex()


class BlockchainRpcClient(Protocol):
    """Protocol for querying JSON-RPC nodes."""

    async def get_latest_block_number(self) -> int: ...

    async def get_block_by_number(self, block_number: int) -> Optional[Dict[str, Any]]: ...

    async def get_logs(
        self,
        from_block: int,
        to_block: int,
        address: str,
        topics: Optional[List[Optional[str]]] = None,
    ) -> List[Dict[str, Any]]: ...


class HttpRpcClient:
    """Async HTTP JSON-RPC client for Celo network."""

    def __init__(self, rpc_url: Optional[str] = None):
        self.rpc_url = rpc_url or settings.CELO_RPC_URL

    async def get_latest_block_number(self) -> int:
        payload = {"jsonrpc": "2.0", "method": "eth_blockNumber", "params": [], "id": 1}
        async with httpx.AsyncClient(timeout=10.0) as client:
            resp = await client.post(self.rpc_url, json=payload)
            resp.raise_for_status()
            data = resp.json()
            return int(data["result"], 16)

    async def get_block_by_number(self, block_number: int) -> Optional[Dict[str, Any]]:
        payload = {
            "jsonrpc": "2.0",
            "method": "eth_getBlockByNumber",
            "params": [hex(block_number), False],
            "id": 1,
        }
        async with httpx.AsyncClient(timeout=10.0) as client:
            resp = await client.post(self.rpc_url, json=payload)
            resp.raise_for_status()
            data = resp.json()
            return cast(Optional[Dict[str, Any]], data.get("result"))

    async def get_logs(
        self,
        from_block: int,
        to_block: int,
        address: str,
        topics: Optional[List[Optional[str]]] = None,
    ) -> List[Dict[str, Any]]:
        params: Dict[str, Any] = {
            "fromBlock": hex(from_block),
            "toBlock": hex(to_block),
            "address": address,
        }
        if topics:
            params["topics"] = topics
        payload = {"jsonrpc": "2.0", "method": "eth_getLogs", "params": [params], "id": 1}
        async with httpx.AsyncClient(timeout=15.0) as client:
            resp = await client.post(self.rpc_url, json=payload)
            resp.raise_for_status()
            data = resp.json()
            return cast(List[Dict[str, Any]], data.get("result", []))


class BlockchainIndexerService:
    """Event ingestion engine synchronizing Celo smart contract events with double-entry ledgers."""

    def __init__(
        self,
        db: AsyncSession,
        ledger_service: Optional[LedgerService] = None,
        rpc_client: Optional[BlockchainRpcClient] = None,
        chain_id: Optional[int] = None,
        contract_address: Optional[str] = None,
        confirmation_depth: int = 5,
    ):
        self.db = db
        self.ledger_service = ledger_service or LedgerService(db)
        self.rpc_client = rpc_client or HttpRpcClient()
        self.chain_id = chain_id or settings.CELO_CHAIN_ID
        self.contract_address = (contract_address or settings.ESCROW_CONTRACT_ADDRESS).lower()
        self.confirmation_depth = confirmation_depth

    async def get_or_create_sync_state(self, start_block: int = 0) -> IndexerSyncState:
        """Fetch or initialize the block sync cursor for this contract."""
        query = select(IndexerSyncState).where(IndexerSyncState.chain_id == self.chain_id)
        state = (await self.db.execute(query)).scalar_one_or_none()
        if not state:
            state = IndexerSyncState(
                chain_id=self.chain_id,
                contract_address=self.contract_address,
                last_processed_block=start_block,
            )
            self.db.add(state)
            await self.db.flush()
        return state

    async def sync_events(
        self,
        batch_size: int = 1000,
        override_to_block: Optional[int] = None,
    ) -> Tuple[int, int]:
        """Fetch, deduplicate, persist, and process unindexed events up to confirmed block height.

        Returns (events_indexed_count, last_processed_block).
        """
        # 1. Detect and compensate for any blockchain reorganizations
        await self.detect_and_handle_reorg()

        sync_state = await self.get_or_create_sync_state()
        from_block = sync_state.last_processed_block + 1

        if override_to_block is not None:
            safe_head = override_to_block
        else:
            latest_block = await self.rpc_client.get_latest_block_number()
            safe_head = max(0, latest_block - self.confirmation_depth)

        if from_block > safe_head:
            return 0, sync_state.last_processed_block

        to_block = min(from_block + batch_size - 1, safe_head)

        logs = await self.rpc_client.get_logs(
            from_block=from_block,
            to_block=to_block,
            address=self.contract_address,
        )

        indexed_count = 0
        for log in logs:
            processed = await self._process_log(log, safe_head)
            if processed:
                indexed_count += 1

        sync_state.last_processed_block = to_block
        sync_state.last_sync_timestamp = datetime.now(timezone.utc)
        await self.db.flush()

        return indexed_count, to_block

    async def detect_and_handle_reorg(self) -> bool:
        """
        Detect whether previously indexed blocks have been orphaned due to a chain reorganization.
        If a reorg is detected, mark affected events as ORPHANED, compensate ledger mutations,
        revert payout/submission statuses, and rewind the last_processed_block.
        Returns True if a reorg occurred, False otherwise.
        """
        recent_events_query = (
            select(BlockchainEvent)
            .where(
                BlockchainEvent.chain_id == self.chain_id,
                BlockchainEvent.status != BlockchainEventStatus.ORPHANED.value,
            )
            .order_by(BlockchainEvent.block_number.desc())
            .limit(20)
        )
        recent_events = (await self.db.execute(recent_events_query)).scalars().all()
        if not recent_events:
            return False

        checked_blocks: Dict[int, str] = {}
        first_diverged_block: Optional[int] = None

        for ev in recent_events:
            b_num = ev.block_number
            if b_num not in checked_blocks:
                if hasattr(self.rpc_client, "get_block_by_number"):
                    block_info = await self.rpc_client.get_block_by_number(b_num)
                    if block_info and "hash" in block_info:
                        checked_blocks[b_num] = block_info["hash"].lower()
                    else:
                        continue
                else:
                    continue

            canonical_hash = checked_blocks.get(b_num)
            if canonical_hash and ev.block_hash.lower() != canonical_hash:
                logger.warning(
                    "Blockchain reorg detected at block %d: indexed hash %s != canonical hash %s",
                    b_num,
                    ev.block_hash,
                    canonical_hash,
                )
                if first_diverged_block is None or b_num < first_diverged_block:
                    first_diverged_block = b_num

        if first_diverged_block is None:
            return False

        await self._compensate_orphaned_events(first_diverged_block)
        return True

    async def _compensate_orphaned_events(self, reorg_block: int) -> int:
        """Rollback all indexed state mutations from reorg_block onwards."""
        orphaned_query = (
            select(BlockchainEvent)
            .where(
                BlockchainEvent.chain_id == self.chain_id,
                BlockchainEvent.block_number >= reorg_block,
                BlockchainEvent.status != BlockchainEventStatus.ORPHANED.value,
            )
            .order_by(BlockchainEvent.block_number.desc(), BlockchainEvent.log_index.desc())
        )
        orphaned_events = (await self.db.execute(orphaned_query)).scalars().all()
        compensated_count = 0

        for ev in orphaned_events:
            params = ev.parameters or {}
            tx_hash = ev.transaction_hash
            log_idx = ev.log_index

            if ev.event_name == "RewardClaimed":
                nonce = params.get("nonce")
                amount_cusd = Decimal(str(params.get("amount_cusd", "0")))
                if nonce and amount_cusd > 0:
                    payout_query = (
                        select(PayoutAuthorization)
                        .where(PayoutAuthorization.nonce == nonce)
                        .options(
                            selectinload(PayoutAuthorization.submission).selectinload(
                                Submission.campaign
                            )
                        )
                    )
                    payout = (await self.db.execute(payout_query)).scalar_one_or_none()
                    if payout:
                        payout.status = PayoutStatus.AUTHORIZED.value
                        payout.claim_tx_hash = None
                        payout.claimed_at = None
                        payout.submission.status = SubmissionStatus.APPROVED.value

                        comp_ref = f"reorg_unclaim_{tx_hash}_{log_idx}"
                        await self.ledger_service.compensate_claim_reversal(
                            campaign_id=payout.submission.campaign_id,
                            amount=amount_cusd,
                            reference_id=comp_ref,
                            notes=f"Reorg rollback of orphaned claim {tx_hash}",
                        )

            elif ev.event_name == "CampaignFunded":
                campaign_id = params.get("campaignId")
                amount_cusd = Decimal(str(params.get("amount_cusd", "0")))
                if campaign_id and amount_cusd > 0:
                    escrow_query = select(EscrowCampaign).where(
                        EscrowCampaign.onchain_campaign_id == campaign_id
                    )
                    escrow = (await self.db.execute(escrow_query)).scalar_one_or_none()
                    if escrow:
                        comp_ref = f"reorg_undep_{tx_hash}_{log_idx}"
                        await self.ledger_service.compensate_deposit_reversal(
                            campaign_id=escrow.campaign_id,
                            amount=amount_cusd,
                            reference_id=comp_ref,
                            notes=f"Reorg rollback of orphaned deposit {tx_hash}",
                        )

            elif ev.event_name == "CampaignRefunded":
                campaign_id = params.get("campaignId")
                amount_cusd = Decimal(str(params.get("amount_cusd", "0")))
                if campaign_id and amount_cusd > 0:
                    escrow_query = select(EscrowCampaign).where(
                        EscrowCampaign.onchain_campaign_id == campaign_id
                    )
                    escrow = (await self.db.execute(escrow_query)).scalar_one_or_none()
                    if escrow:
                        comp_ref = f"reorg_unref_{tx_hash}_{log_idx}"
                        await self.ledger_service.compensate_refund_reversal(
                            campaign_id=escrow.campaign_id,
                            amount=amount_cusd,
                            reference_id=comp_ref,
                            notes=f"Reorg rollback of orphaned refund {tx_hash}",
                        )

            ev.status = BlockchainEventStatus.ORPHANED.value
            compensated_count += 1

        sync_state = await self.get_or_create_sync_state()
        sync_state.last_processed_block = max(0, reorg_block - 1)
        sync_state.last_sync_timestamp = datetime.now(timezone.utc)
        await self.db.flush()

        logger.info(
            "Reorg compensation complete: %d events orphaned, cursor rewound to block %d",
            compensated_count,
            sync_state.last_processed_block,
        )
        return compensated_count

    async def _process_log(self, log: Dict[str, Any], current_safe_block: int) -> bool:
        """Parse raw log, perform idempotency checks, and trigger financial updates."""
        tx_hash = log["transactionHash"]
        log_index = (
            int(log["logIndex"], 16) if isinstance(log["logIndex"], str) else int(log["logIndex"])
        )
        block_number = (
            int(log["blockNumber"], 16)
            if isinstance(log["blockNumber"], str)
            else int(log["blockNumber"])
        )
        block_hash = log.get("blockHash", "0x" + "0" * 64)
        topics = log.get("topics", [])
        data = log.get("data", "0x")

        if not topics:
            return False

        topic0 = topics[0].lower()

        # Idempotency check on (transaction_hash, log_index)
        existing_event_query = select(BlockchainEvent).where(
            BlockchainEvent.transaction_hash == tx_hash,
            BlockchainEvent.log_index == log_index,
        )
        existing_event = (await self.db.execute(existing_event_query)).scalar_one_or_none()
        if existing_event:
            return False

        confirmations = max(0, current_safe_block - block_number + self.confirmation_depth)
        is_confirmed = confirmations >= self.confirmation_depth

        event_name = "UNKNOWN"
        parameters: Dict[str, Any] = {}

        if topic0 == TOPIC_CAMPAIGN_FUNDED.lower():
            event_name = "CampaignFunded"
            campaign_id = topics[1] if len(topics) > 1 else None
            funder = "0x" + topics[2][-40:] if len(topics) > 2 else None
            # Data: amount (uint256), totalFunded (uint256)
            data_clean = data[2:] if data.startswith("0x") else data
            amount_wei = int(data_clean[:64], 16) if len(data_clean) >= 64 else 0
            total_funded_wei = int(data_clean[64:128], 16) if len(data_clean) >= 128 else 0
            amount_cusd = Decimal(amount_wei) / Decimal(10**18)
            parameters = {
                "campaignId": campaign_id,
                "funder": funder,
                "amount_wei": amount_wei,
                "amount_cusd": str(amount_cusd),
                "total_funded_wei": total_funded_wei,
            }

            if is_confirmed and campaign_id:
                await self._handle_campaign_funded(
                    campaign_id=campaign_id,
                    amount=amount_cusd,
                    tx_hash=tx_hash,
                    log_index=log_index,
                )

        elif topic0 == TOPIC_REWARD_CLAIMED.lower():
            event_name = "RewardClaimed"
            campaign_id = topics[1] if len(topics) > 1 else None
            contributor = "0x" + topics[2][-40:] if len(topics) > 2 else None
            nonce = topics[3] if len(topics) > 3 else None
            # Data: amount (uint256), voucherHash (bytes32)
            data_clean = data[2:] if data.startswith("0x") else data
            amount_wei = int(data_clean[:64], 16) if len(data_clean) >= 64 else 0
            voucher_hash = "0x" + data_clean[64:128] if len(data_clean) >= 128 else None
            amount_cusd = Decimal(amount_wei) / Decimal(10**18)
            parameters = {
                "campaignId": campaign_id,
                "contributor": contributor,
                "nonce": nonce,
                "amount_wei": amount_wei,
                "amount_cusd": str(amount_cusd),
                "voucherHash": voucher_hash,
            }

            if is_confirmed and nonce:
                await self._handle_reward_claimed(
                    nonce=nonce,
                    amount=amount_cusd,
                    tx_hash=tx_hash,
                    log_index=log_index,
                )

        elif topic0 == TOPIC_CAMPAIGN_REFUNDED.lower():
            event_name = "CampaignRefunded"
            campaign_id = topics[1] if len(topics) > 1 else None
            recipient = "0x" + topics[2][-40:] if len(topics) > 2 else None
            data_clean = data[2:] if data.startswith("0x") else data
            amount_wei = int(data_clean[:64], 16) if len(data_clean) >= 64 else 0
            amount_cusd = Decimal(amount_wei) / Decimal(10**18)
            parameters = {
                "campaignId": campaign_id,
                "recipient": recipient,
                "amount_wei": amount_wei,
                "amount_cusd": str(amount_cusd),
            }

            if is_confirmed and campaign_id:
                await self._handle_campaign_refunded(
                    campaign_id=campaign_id,
                    amount=amount_cusd,
                    tx_hash=tx_hash,
                    log_index=log_index,
                )

        elif topic0 == TOPIC_CAMPAIGN_ACTIVATED.lower():
            event_name = "CampaignActivated"
            campaign_id = topics[1] if len(topics) > 1 else None
            parameters = {"campaignId": campaign_id}

        elif topic0 == TOPIC_CAMPAIGN_CANCELLED.lower():
            event_name = "CampaignCancelled"
            campaign_id = topics[1] if len(topics) > 1 else None
            account = "0x" + topics[2][-40:] if len(topics) > 2 else None
            parameters = {"campaignId": campaign_id, "account": account}

            if is_confirmed and campaign_id:
                await self._handle_campaign_cancelled(
                    campaign_id=campaign_id,
                    tx_hash=tx_hash,
                    log_index=log_index,
                )

        elif topic0 == TOPIC_CAMPAIGN_CLOSED.lower():
            event_name = "CampaignClosed"
            campaign_id = topics[1] if len(topics) > 1 else None
            parameters = {"campaignId": campaign_id}

            if is_confirmed and campaign_id:
                await self._handle_campaign_closed(
                    campaign_id=campaign_id,
                    tx_hash=tx_hash,
                    log_index=log_index,
                )

        event = BlockchainEvent(
            chain_id=self.chain_id,
            contract_address=self.contract_address,
            event_name=event_name,
            transaction_hash=tx_hash,
            block_number=block_number,
            block_hash=block_hash,
            log_index=log_index,
            parameters=parameters,
            is_confirmed=is_confirmed,
            confirmations=confirmations,
            status=BlockchainEventStatus.PROCESSED.value
            if is_confirmed
            else BlockchainEventStatus.INDEXED.value,
            processed_at=datetime.now(timezone.utc) if is_confirmed else None,
        )
        self.db.add(event)
        await self.db.flush()
        return True

    async def _handle_campaign_funded(
        self, campaign_id: str, amount: Decimal, tx_hash: str, log_index: int
    ) -> None:
        """Record on-chain deposit event in the double-entry financial ledger."""
        escrow_query = (
            select(EscrowCampaign)
            .where(EscrowCampaign.onchain_campaign_id == campaign_id)
            .options(selectinload(EscrowCampaign.campaign))
        )
        escrow = (await self.db.execute(escrow_query)).scalar_one_or_none()
        if escrow:
            reference_id = f"onchain_dep_{tx_hash}_{log_index}"
            await self.ledger_service.record_deposit(
                campaign_id=escrow.campaign_id,
                amount=amount,
                reference_id=reference_id,
                onchain_campaign_id=campaign_id,
                notes=f"Confirmed on-chain deposit tx {tx_hash}",
            )
            if escrow.campaign:
                notif = Notification(
                    user_id=escrow.campaign.creator_id,
                    event_type="CAMPAIGN_FUNDING_CONFIRMED",
                    title="Campaign Funding Confirmed",
                    message=f"Funding of {amount} cUSD confirmed on Celo for campaign '{escrow.campaign.title}'.",
                    data_json={
                        "campaign_id": str(escrow.campaign_id),
                        "amount": str(amount),
                        "tx_hash": tx_hash,
                    },
                )
                self.db.add(notif)

    async def _handle_reward_claimed(
        self, nonce: str, amount: Decimal, tx_hash: str, log_index: int
    ) -> None:
        """Settle claimed reward in ledger and update payout & submission state."""
        payout_query = (
            select(PayoutAuthorization)
            .where(PayoutAuthorization.nonce == nonce)
            .options(selectinload(PayoutAuthorization.submission).selectinload(Submission.campaign))
        )
        payout = (await self.db.execute(payout_query)).scalar_one_or_none()
        if payout:
            payout.status = PayoutStatus.CLAIMED.value
            payout.claim_tx_hash = tx_hash
            payout.claimed_at = datetime.now(timezone.utc)

            submission = payout.submission
            submission.status = SubmissionStatus.SETTLED.value

            reference_id = f"onchain_claim_{tx_hash}_{log_index}"
            await self.ledger_service.record_claim(
                campaign_id=submission.campaign_id,
                amount=amount,
                reference_id=reference_id,
                notes=f"Confirmed on-chain claim tx {tx_hash} (nonce {nonce})",
            )

            campaign_title = submission.campaign.title if submission.campaign else "campaign"
            notif = Notification(
                user_id=payout.contributor_id,
                event_type="REWARD_CLAIM_CONFIRMED",
                title="Reward Claim Settled On-Chain",
                message=f"Your reward claim of {amount} cUSD for {campaign_title} has settled on-chain.",
                data_json={
                    "submission_id": str(submission.id),
                    "amount": str(amount),
                    "tx_hash": tx_hash,
                },
            )
            self.db.add(notif)

    async def _handle_campaign_refunded(
        self, campaign_id: str, amount: Decimal, tx_hash: str, log_index: int
    ) -> None:
        """Record on-chain creator refund in financial ledger."""
        escrow_query = select(EscrowCampaign).where(
            EscrowCampaign.onchain_campaign_id == campaign_id
        )
        escrow = (await self.db.execute(escrow_query)).scalar_one_or_none()
        if escrow:
            reference_id = f"onchain_ref_{tx_hash}_{log_index}"
            await self.ledger_service.record_refund(
                campaign_id=escrow.campaign_id,
                amount=amount,
                reference_id=reference_id,
                notes=f"Confirmed on-chain refund tx {tx_hash}",
            )

    async def _handle_campaign_cancelled(
        self, campaign_id: str, tx_hash: str, log_index: int
    ) -> None:
        """Update campaign status upon confirmed on-chain cancellation."""
        query = (
            select(EscrowCampaign)
            .where(EscrowCampaign.onchain_campaign_id == campaign_id)
            .options(selectinload(EscrowCampaign.campaign))
        )
        escrow = (await self.db.execute(query)).scalar_one_or_none()
        if escrow and escrow.campaign:
            escrow.campaign.status = CampaignStatus.CANCELLED.value
            notif = Notification(
                user_id=escrow.campaign.creator_id,
                event_type="CAMPAIGN_CANCELLED",
                title="Campaign Cancelled On-Chain",
                message=f"Campaign '{escrow.campaign.title}' has been cancelled on-chain in tx {tx_hash}.",
                data_json={"campaign_id": str(escrow.campaign.id), "tx_hash": tx_hash},
            )
            self.db.add(notif)

    async def _handle_campaign_closed(self, campaign_id: str, tx_hash: str, log_index: int) -> None:
        """Update campaign status upon final closure."""
        query = (
            select(EscrowCampaign)
            .where(EscrowCampaign.onchain_campaign_id == campaign_id)
            .options(selectinload(EscrowCampaign.campaign))
        )
        escrow = (await self.db.execute(query)).scalar_one_or_none()
        if escrow and escrow.campaign:
            escrow.campaign.status = CampaignStatus.COMPLETED.value
            notif = Notification(
                user_id=escrow.campaign.creator_id,
                event_type="CAMPAIGN_COMPLETED",
                title="Campaign Closed On-Chain",
                message=f"Campaign '{escrow.campaign.title}' has finalized and closed on-chain.",
                data_json={"campaign_id": str(escrow.campaign.id), "tx_hash": tx_hash},
            )
            self.db.add(notif)
