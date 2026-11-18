"""Celery tasks for async validation, EIP-712 reward generation, blockchain indexing, and reconciliation."""

import asyncio
import logging
import uuid
from datetime import datetime, timezone
from typing import Any, Coroutine

from sqlalchemy import select

from app.core.database import AsyncSessionLocal
from app.models.enums import OutboxStatus, PayoutStatus, ValidationOutcome
from app.models.financial import PayoutAuthorization
from app.models.notification import Notification, OutboxEvent
from app.services.blockchain_indexer import BlockchainIndexerService
from app.services.payout_signer import PayoutSignerService
from app.services.reconciliation_service import ReconciliationService
from app.services.validation.validation_service import ValidationService
from app.workers.celery_app import celery_app

logger = logging.getLogger(__name__)


def run_async(coro: Coroutine[Any, Any, Any]) -> Any:
    """Helper running async coroutine synchronously inside Celery worker or test environment."""
    try:
        loop = asyncio.get_running_loop()
    except RuntimeError:
        loop = None

    if loop and loop.is_running():
        import concurrent.futures

        with concurrent.futures.ThreadPoolExecutor(max_workers=1) as executor:
            return executor.submit(asyncio.run, coro).result()
    return asyncio.run(coro)


async def execute_ai_validation(submission_id_str: str) -> dict:
    """Async execution logic for AI validation task."""
    sub_uuid = uuid.UUID(submission_id_str)
    async with AsyncSessionLocal() as session:
        try:
            val_service = ValidationService(session)
            sub, run, outcome = await val_service.validate_submission(sub_uuid)

            # If approved, schedule voucher generation
            if outcome == ValidationOutcome.APPROVED:
                task_generate_payout_voucher.delay(str(sub.id))

            # Queue notification for contributor
            notif = Notification(
                user_id=sub.contributor_id,
                event_type="SUBMISSION_VALIDATED",
                title=f"Submission {outcome.value}",
                message=f"Your submission for {sub.campaign.title if sub.campaign else 'campaign'} has been evaluated: {outcome.value}.",
                data_json={
                    "submission_id": str(sub.id),
                    "outcome": outcome.value,
                    "score": str(run.score) if run.score else None,
                },
            )
            session.add(notif)
            await session.commit()

            return {
                "submission_id": str(sub.id),
                "outcome": outcome.value,
                "score": str(run.score) if run.score else None,
            }
        except Exception as exc:
            await session.rollback()
            logger.exception("Failed to run AI validation for submission %s: %s", sub_uuid, exc)
            raise exc


@celery_app.task(name="app.workers.tasks.task_run_ai_validation", bind=True, max_retries=3)
def task_run_ai_validation(self: Any, submission_id_str: str) -> dict:
    """Run multi-modal validation pipeline asynchronously on a submitted dataset entry."""
    return run_async(execute_ai_validation(submission_id_str))


async def execute_generate_payout_voucher(submission_id_str: str) -> dict:
    """Async execution logic for voucher generation."""
    sub_uuid = uuid.UUID(submission_id_str)
    async with AsyncSessionLocal() as session:
        try:
            payout_service = PayoutSignerService(session)
            payout = await payout_service.generate_payout_voucher(sub_uuid)

            notif = Notification(
                user_id=payout.contributor_id,
                event_type="REWARD_VOUCHER_READY",
                title="Reward Ready to Claim",
                message=f"Your reward voucher for {payout.amount} cUSD is signed and ready for on-chain withdrawal.",
                data_json={
                    "payout_id": str(payout.id),
                    "amount": str(payout.amount),
                    "nonce": payout.nonce,
                },
            )
            session.add(notif)
            await session.commit()

            return {
                "payout_id": str(payout.id),
                "submission_id": str(payout.submission_id),
                "amount": str(payout.amount),
                "nonce": payout.nonce,
                "status": payout.status,
            }
        except Exception as exc:
            await session.rollback()
            logger.exception(
                "Failed to generate payout voucher for submission %s: %s", sub_uuid, exc
            )
            raise exc


@celery_app.task(name="app.workers.tasks.task_generate_payout_voucher", bind=True, max_retries=3)
def task_generate_payout_voucher(self: Any, submission_id_str: str) -> dict:
    """Generate and sign EIP-712 reward authorization voucher for an approved submission."""
    return run_async(execute_generate_payout_voucher(submission_id_str))


async def execute_index_blockchain_events(batch_size: int = 1000) -> dict:
    """Async execution logic for indexing blockchain events."""
    async with AsyncSessionLocal() as session:
        try:
            indexer = BlockchainIndexerService(session)
            indexed_count, last_block = await indexer.sync_events(batch_size=batch_size)
            await session.commit()
            return {"indexed_count": indexed_count, "last_processed_block": last_block}
        except Exception as exc:
            await session.rollback()
            logger.exception("Blockchain indexer periodic sync failed: %s", exc)
            raise exc


@celery_app.task(name="app.workers.tasks.task_index_blockchain_events")
def task_index_blockchain_events(batch_size: int = 1000) -> dict:
    """Index and process latest confirmed Celo smart contract events."""
    return run_async(execute_index_blockchain_events(batch_size))


async def execute_reconcile_escrow_balances() -> dict:
    """Async execution logic for reconciling escrow balances."""
    async with AsyncSessionLocal() as session:
        try:
            recon_service = ReconciliationService(session)
            reports = await recon_service.reconcile_all_campaigns()
            discrepant = [r for r in reports if not r.is_reconciled]
            return {
                "total_campaigns_audited": len(reports),
                "discrepant_count": len(discrepant),
                "discrepant_campaign_ids": [str(d.campaign_id) for d in discrepant],
            }
        except Exception as exc:
            await session.rollback()
            logger.exception("Escrow reconciliation task failed: %s", exc)
            raise exc


@celery_app.task(name="app.workers.tasks.task_reconcile_escrow_balances")
def task_reconcile_escrow_balances() -> dict:
    """Periodically audit campaign financial ledgers against components and on-chain values."""
    return run_async(execute_reconcile_escrow_balances())


async def execute_expire_stale_authorizations() -> dict:
    """Async execution logic for expiring stale authorizations."""
    async with AsyncSessionLocal() as session:
        try:
            now_utc = datetime.now(timezone.utc)
            query = select(PayoutAuthorization).where(
                PayoutAuthorization.status == PayoutStatus.AUTHORIZED.value,
                PayoutAuthorization.expires_at < now_utc,
            )
            expired_payouts = (await session.execute(query)).scalars().all()

            payout_service = PayoutSignerService(session)
            expired_count = 0
            for p in expired_payouts:
                await payout_service.expire_payout_voucher(p.id)
                expired_count += 1

            await session.commit()
            return {"expired_count": expired_count}
        except Exception as exc:
            await session.rollback()
            logger.exception("Expire stale authorizations task failed: %s", exc)
            raise exc


@celery_app.task(name="app.workers.tasks.task_expire_stale_authorizations")
def task_expire_stale_authorizations() -> dict:
    """Scan and expire payout vouchers past deadline, releasing reserved escrow funds."""
    return run_async(execute_expire_stale_authorizations())


async def execute_dispatch_outbox_notifications(batch_size: int = 50) -> dict:
    """Async execution logic for dispatching outbox notifications."""
    async with AsyncSessionLocal() as session:
        try:
            query = (
                select(OutboxEvent)
                .where(OutboxEvent.status == OutboxStatus.PENDING.value)
                .order_by(OutboxEvent.created_at.asc())
                .limit(batch_size)
            )
            events = (await session.execute(query)).scalars().all()
            dispatched_count = 0

            for ev in events:
                if ev.topic == "submission.submitted":
                    sub_id_str = ev.payload.get("submission_id")
                    if sub_id_str:
                        task_run_ai_validation.delay(sub_id_str)
                ev.status = OutboxStatus.PUBLISHED.value
                dispatched_count += 1

            await session.commit()
            return {"dispatched_count": dispatched_count}
        except Exception as exc:
            await session.rollback()
            logger.exception("Outbox event dispatch task failed: %s", exc)
            raise exc


@celery_app.task(name="app.workers.tasks.task_dispatch_outbox_notifications")
def task_dispatch_outbox_notifications(batch_size: int = 50) -> dict:
    """Publish pending outbox events to external queues or subscribers."""
    return run_async(execute_dispatch_outbox_notifications(batch_size))
