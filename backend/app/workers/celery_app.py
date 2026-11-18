"""Celery application configuration and periodic task schedules."""

from celery import Celery

from app.core.config import settings

celery_app = Celery(
    "datamint",
    broker=settings.REDIS_URL,
    backend=settings.REDIS_URL,
    include=["app.workers.tasks"],
)

celery_app.conf.update(
    task_serializer="json",
    accept_content=["json"],
    result_serializer="json",
    timezone="UTC",
    enable_utc=True,
    task_track_started=True,
    task_acks_late=True,
    worker_prefetch_multiplier=1,
    beat_schedule={
        "index-celo-blockchain-events": {
            "task": "app.workers.tasks.task_index_blockchain_events",
            "schedule": 15.0,  # Every 15 seconds
        },
        "expire-stale-payout-authorizations": {
            "task": "app.workers.tasks.task_expire_stale_authorizations",
            "schedule": 600.0,  # Every 10 minutes
        },
        "reconcile-escrow-balances-hourly": {
            "task": "app.workers.tasks.task_reconcile_escrow_balances",
            "schedule": 3600.0,  # Hourly
        },
        "dispatch-outbox-notifications": {
            "task": "app.workers.tasks.task_dispatch_outbox_notifications",
            "schedule": 30.0,  # Every 30 seconds
        },
    },
)
