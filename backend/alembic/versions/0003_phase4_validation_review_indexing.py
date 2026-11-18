"""Phase 4 schema additions: AI validation metadata, reviews, appeals, blockchain events, indexer state, and notifications

Revision ID: 0003_phase4_validation_review_indexing
Revises: 0002_phase3_core_workflows
Create Date: 2026-11-18 15:00:00.000000

"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision: str = "0003_phase4_validation_review_indexing"
down_revision: Union[str, None] = "0002_phase3_core_workflows"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # 1. validation_runs additions
    op.add_column("validation_runs", sa.Column("ai_provider", sa.String(50), nullable=True))
    op.add_column("validation_runs", sa.Column("model_version", sa.String(50), nullable=True))
    op.add_column("validation_runs", sa.Column("policy_version", sa.String(20), nullable=False, server_default="1.0"))
    op.add_column("validation_runs", sa.Column("execution_duration_ms", sa.Integer(), nullable=True))
    op.add_column("validation_runs", sa.Column("failure_reason", sa.Text(), nullable=True))

    # 2. validation_findings additions
    op.add_column("validation_findings", sa.Column("is_deterministic", sa.Boolean(), nullable=False, server_default=sa.false()))
    op.add_column("validation_findings", sa.Column("evidence", sa.Text(), nullable=True))

    # 3. reviews additions
    op.add_column("reviews", sa.Column("review_type", sa.String(50), nullable=False, server_default="MANUAL_VALIDATION"))
    op.add_column("reviews", sa.Column("rejection_reason", sa.Text(), nullable=True))
    op.add_column("reviews", sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()))

    # 4. appeals table
    op.create_table(
        "appeals",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("submission_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("submissions.id", ondelete="CASCADE"), nullable=False),
        sa.Column("contributor_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("users.id", ondelete="RESTRICT"), nullable=False),
        sa.Column("reason", sa.Text(), nullable=False),
        sa.Column("evidence", postgresql.JSONB(), nullable=True),
        sa.Column("status", sa.String(50), nullable=False, server_default="PENDING"),
        sa.Column("reviewer_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("users.id", ondelete="SET NULL"), nullable=True),
        sa.Column("reviewer_notes", sa.Text(), nullable=True),
        sa.Column("resolved_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
    )
    op.create_index("ix_appeals_submission_id", "appeals", ["submission_id"])
    op.create_index("ix_appeals_contributor_id", "appeals", ["contributor_id"])
    op.create_index("ix_appeals_status", "appeals", ["status"])

    # 5. payout_authorizations additions
    op.add_column("payout_authorizations", sa.Column("nonce", sa.String(66), nullable=True))
    op.add_column("payout_authorizations", sa.Column("onchain_campaign_id", sa.String(66), nullable=True))
    op.add_column("payout_authorizations", sa.Column("deadline", sa.BigInteger(), nullable=True))
    op.add_column("payout_authorizations", sa.Column("claim_tx_hash", sa.String(66), nullable=True))
    op.add_column("payout_authorizations", sa.Column("claimed_at", sa.DateTime(timezone=True), nullable=True))
    op.create_index("ix_payout_authorizations_nonce", "payout_authorizations", ["nonce"], unique=True)
    op.create_index("ix_payout_authorizations_onchain_campaign_id", "payout_authorizations", ["onchain_campaign_id"])
    op.create_index("ix_payout_authorizations_claim_tx_hash", "payout_authorizations", ["claim_tx_hash"])

    # 6. blockchain_events table
    op.create_table(
        "blockchain_events",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("chain_id", sa.Integer(), nullable=False),
        sa.Column("contract_address", sa.String(42), nullable=False),
        sa.Column("event_name", sa.String(100), nullable=False),
        sa.Column("transaction_hash", sa.String(66), nullable=False),
        sa.Column("block_number", sa.BigInteger(), nullable=False),
        sa.Column("block_hash", sa.String(66), nullable=False),
        sa.Column("log_index", sa.Integer(), nullable=False),
        sa.Column("parameters", postgresql.JSONB(), nullable=False),
        sa.Column("is_confirmed", sa.Boolean(), nullable=False, server_default=sa.false()),
        sa.Column("confirmations", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("status", sa.String(50), nullable=False, server_default="INDEXED"),
        sa.Column("processed_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.UniqueConstraint("transaction_hash", "log_index", name="uq_blockchain_events_tx_log"),
    )
    op.create_index("ix_blockchain_events_chain_id", "blockchain_events", ["chain_id"])
    op.create_index("ix_blockchain_events_contract", "blockchain_events", ["contract_address"])
    op.create_index("ix_blockchain_events_name_block", "blockchain_events", ["event_name", "block_number"])
    op.create_index("ix_blockchain_events_tx_hash", "blockchain_events", ["transaction_hash"])
    op.create_index("ix_blockchain_events_status", "blockchain_events", ["status"])

    # 7. indexer_sync_state table
    op.create_table(
        "indexer_sync_state",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("chain_id", sa.Integer(), nullable=False, unique=True),
        sa.Column("contract_address", sa.String(42), nullable=False),
        sa.Column("last_processed_block", sa.BigInteger(), nullable=False, server_default="0"),
        sa.Column("last_sync_timestamp", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
    )

    # 8. notifications table
    op.create_table(
        "notifications",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("user_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("event_type", sa.String(100), nullable=False),
        sa.Column("title", sa.String(255), nullable=False),
        sa.Column("message", sa.Text(), nullable=False),
        sa.Column("data_json", postgresql.JSONB(), nullable=True),
        sa.Column("is_read", sa.Boolean(), nullable=False, server_default=sa.false()),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
    )
    op.create_index("ix_notifications_user_id", "notifications", ["user_id"])
    op.create_index("ix_notifications_event_type", "notifications", ["event_type"])

    # 9. outbox_events table
    op.create_table(
        "outbox_events",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("topic", sa.String(100), nullable=False),
        sa.Column("payload", postgresql.JSONB(), nullable=False),
        sa.Column("status", sa.String(50), nullable=False, server_default="PENDING"),
        sa.Column("retry_count", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
    )
    op.create_index("ix_outbox_events_topic", "outbox_events", ["topic"])
    op.create_index("ix_outbox_events_status", "outbox_events", ["status"])


def downgrade() -> None:
    op.drop_table("outbox_events")
    op.drop_table("notifications")
    op.drop_table("indexer_sync_state")
    op.drop_table("blockchain_events")
    op.drop_index("ix_payout_authorizations_claim_tx_hash", table_name="payout_authorizations")
    op.drop_index("ix_payout_authorizations_onchain_campaign_id", table_name="payout_authorizations")
    op.drop_index("ix_payout_authorizations_nonce", table_name="payout_authorizations")
    op.drop_column("payout_authorizations", "claimed_at")
    op.drop_column("payout_authorizations", "claim_tx_hash")
    op.drop_column("payout_authorizations", "deadline")
    op.drop_column("payout_authorizations", "onchain_campaign_id")
    op.drop_column("payout_authorizations", "nonce")
    op.drop_table("appeals")
    op.drop_column("reviews", "updated_at")
    op.drop_column("reviews", "rejection_reason")
    op.drop_column("reviews", "review_type")
    op.drop_column("validation_findings", "evidence")
    op.drop_column("validation_findings", "is_deterministic")
    op.drop_column("validation_runs", "failure_reason")
    op.drop_column("validation_runs", "execution_duration_ms")
    op.drop_column("validation_runs", "policy_version")
    op.drop_column("validation_runs", "model_version")
    op.drop_column("validation_runs", "ai_provider")
