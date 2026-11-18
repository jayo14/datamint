"""Initial PostgreSQL schema for DataMint

Revision ID: 0001_initial_schema
Revises: 
Create Date: 2026-11-18 13:00:00.000000

"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision: str = "0001_initial_schema"
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # 1. users
    op.create_table(
        "users",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("email", sa.String(255), unique=True, nullable=True),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index("ix_users_email", "users", ["email"])

    # 2. user_profiles
    op.create_table(
        "user_profiles",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("user_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("users.id", ondelete="CASCADE"), unique=True, nullable=False),
        sa.Column("display_name", sa.String(100), nullable=True),
        sa.Column("avatar_url", sa.String(500), nullable=True),
        sa.Column("bio", sa.Text(), nullable=True),
        sa.Column("metadata_json", postgresql.JSONB(), nullable=True),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
    )

    # 3. user_capabilities
    op.create_table(
        "user_capabilities",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("user_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("capability_type", sa.String(50), nullable=False),
        sa.Column("is_enabled", sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column("granted_at", sa.DateTime(timezone=True), nullable=False),
        sa.UniqueConstraint("user_id", "capability_type", name="uq_user_capability"),
    )

    # 4. auth_sessions
    op.create_table(
        "auth_sessions",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("user_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("refresh_token_hash", sa.String(255), unique=True, nullable=False),
        sa.Column("is_revoked", sa.Boolean(), nullable=False, server_default=sa.false()),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index("ix_auth_sessions_user_id", "auth_sessions", ["user_id"])

    # 5. user_wallets
    op.create_table(
        "user_wallets",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("user_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("address", sa.String(42), unique=True, nullable=False),
        sa.Column("chain_id", sa.Integer(), nullable=False, server_default="42220"),
        sa.Column("is_primary", sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column("verified_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index("ix_user_wallets_address", "user_wallets", ["address"])

    # 6. wallet_nonce_challenges
    op.create_table(
        "wallet_nonce_challenges",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("address", sa.String(42), nullable=False),
        sa.Column("nonce", sa.String(64), unique=True, nullable=False),
        sa.Column("chain_id", sa.Integer(), nullable=False, server_default="42220"),
        sa.Column("is_used", sa.Boolean(), nullable=False, server_default=sa.false()),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index("ix_wallet_nonce_challenges_nonce", "wallet_nonce_challenges", ["nonce"])

    # 7. dataset_campaigns
    op.create_table(
        "dataset_campaigns",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("creator_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("users.id", ondelete="RESTRICT"), nullable=False),
        sa.Column("title", sa.String(200), nullable=False),
        sa.Column("description", sa.Text(), nullable=False),
        sa.Column("data_type", sa.String(50), nullable=False),
        sa.Column("status", sa.String(50), nullable=False),
        sa.Column("target_submissions", sa.Integer(), nullable=False),
        sa.Column("current_submissions", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("reward_per_submission", sa.Numeric(18, 4), nullable=False),
        sa.Column("reward_currency", sa.String(10), nullable=False, server_default="cUSD"),
        sa.Column("deadline", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.CheckConstraint("target_submissions > 0", name="chk_target_submissions_positive"),
        sa.CheckConstraint("current_submissions >= 0", name="chk_current_submissions_non_negative"),
        sa.CheckConstraint("reward_per_submission > 0", name="chk_reward_per_submission_positive"),
    )
    op.create_index("ix_campaigns_status_created", "dataset_campaigns", ["status", "created_at"])

    # 8. campaign_requirements
    op.create_table(
        "campaign_requirements",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("campaign_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("dataset_campaigns.id", ondelete="CASCADE"), unique=True, nullable=False),
        sa.Column("validation_rules", postgresql.JSONB(), nullable=True),
        sa.Column("min_duration_sec", sa.Integer(), nullable=True),
        sa.Column("max_duration_sec", sa.Integer(), nullable=True),
        sa.Column("instructions", sa.Text(), nullable=True),
        sa.Column("criteria_metadata", postgresql.JSONB(), nullable=True),
    )

    # 9. escrow_campaigns
    op.create_table(
        "escrow_campaigns",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("campaign_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("dataset_campaigns.id", ondelete="RESTRICT"), unique=True, nullable=False),
        sa.Column("onchain_campaign_id", sa.String(100), unique=True, nullable=True),
        sa.Column("total_funded", sa.Numeric(24, 6), nullable=False, server_default="0"),
        sa.Column("total_claimed", sa.Numeric(24, 6), nullable=False, server_default="0"),
        sa.Column("total_reserved", sa.Numeric(24, 6), nullable=False, server_default="0"),
        sa.Column("total_available", sa.Numeric(24, 6), nullable=False, server_default="0"),
        sa.Column("total_refunded", sa.Numeric(24, 6), nullable=False, server_default="0"),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.CheckConstraint("total_funded >= 0", name="chk_escrow_funded_non_negative"),
        sa.CheckConstraint("total_claimed >= 0", name="chk_escrow_claimed_non_negative"),
        sa.CheckConstraint("total_reserved >= 0", name="chk_escrow_reserved_non_negative"),
        sa.CheckConstraint("total_available >= 0", name="chk_escrow_available_non_negative"),
        sa.CheckConstraint("total_refunded >= 0", name="chk_escrow_refunded_non_negative"),
    )

    # 10. ledger_entries
    op.create_table(
        "ledger_entries",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("escrow_campaign_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("escrow_campaigns.id", ondelete="RESTRICT"), nullable=False),
        sa.Column("entry_type", sa.String(50), nullable=False),
        sa.Column("amount", sa.Numeric(24, 6), nullable=False),
        sa.Column("running_available", sa.Numeric(24, 6), nullable=False),
        sa.Column("running_reserved", sa.Numeric(24, 6), nullable=False),
        sa.Column("running_claimed", sa.Numeric(24, 6), nullable=False),
        sa.Column("running_refunded", sa.Numeric(24, 6), nullable=False),
        sa.Column("reference_id", sa.String(200), unique=True, nullable=False),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.CheckConstraint("amount > 0", name="chk_ledger_amount_positive"),
    )
    op.create_index("ix_ledger_escrow_created", "ledger_entries", ["escrow_campaign_id", "created_at"])
    op.create_index("ix_ledger_entries_reference_id", "ledger_entries", ["reference_id"])

    # 11. submissions
    op.create_table(
        "submissions",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("campaign_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("dataset_campaigns.id", ondelete="RESTRICT"), nullable=False),
        sa.Column("contributor_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("users.id", ondelete="RESTRICT"), nullable=False),
        sa.Column("status", sa.String(50), nullable=False),
        sa.Column("attempt_number", sa.Integer(), nullable=False, server_default="1"),
        sa.Column("metadata_json", postgresql.JSONB(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index("ix_submissions_campaign_status", "submissions", ["campaign_id", "status"])
    op.create_index("ix_submissions_contributor_created", "submissions", ["contributor_id", "created_at"])

    # 12. submission_assets
    op.create_table(
        "submission_assets",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("submission_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("submissions.id", ondelete="CASCADE"), nullable=False),
        sa.Column("asset_type", sa.String(50), nullable=False),
        sa.Column("storage_key", sa.String(500), unique=True, nullable=False),
        sa.Column("byte_size", sa.BigInteger(), nullable=False),
        sa.Column("mime_type", sa.String(100), nullable=False),
        sa.Column("checksum_sha256", sa.String(64), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
    )

    # 13. validation_runs
    op.create_table(
        "validation_runs",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("submission_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("submissions.id", ondelete="CASCADE"), nullable=False),
        sa.Column("validator_type", sa.String(100), nullable=False),
        sa.Column("status", sa.String(50), nullable=False),
        sa.Column("score", sa.Numeric(5, 4), nullable=True),
        sa.Column("raw_output", postgresql.JSONB(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("completed_at", sa.DateTime(timezone=True), nullable=True),
    )

    # 14. validation_findings
    op.create_table(
        "validation_findings",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("validation_run_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("validation_runs.id", ondelete="CASCADE"), nullable=False),
        sa.Column("code", sa.String(100), nullable=False),
        sa.Column("severity", sa.String(20), nullable=False),
        sa.Column("message", sa.Text(), nullable=False),
        sa.Column("details", postgresql.JSONB(), nullable=True),
    )

    # 15. reviews
    op.create_table(
        "reviews",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("submission_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("submissions.id", ondelete="CASCADE"), nullable=False),
        sa.Column("reviewer_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("users.id", ondelete="RESTRICT"), nullable=False),
        sa.Column("decision", sa.String(50), nullable=False),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
    )

    # 16. payout_authorizations
    op.create_table(
        "payout_authorizations",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("submission_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("submissions.id", ondelete="RESTRICT"), unique=True, nullable=False),
        sa.Column("contributor_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("users.id", ondelete="RESTRICT"), nullable=False),
        sa.Column("amount", sa.Numeric(24, 6), nullable=False),
        sa.Column("recipient_address", sa.String(42), nullable=False),
        sa.Column("voucher_hash", sa.String(66), unique=True, nullable=False),
        sa.Column("signature", sa.String(132), nullable=False),
        sa.Column("status", sa.String(50), nullable=False),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index("ix_payout_recipient", "payout_authorizations", ["recipient_address"])

    # 17. idempotency_records
    op.create_table(
        "idempotency_records",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("key", sa.String(255), unique=True, nullable=False),
        sa.Column("scope", sa.String(100), nullable=False),
        sa.Column("response_payload", postgresql.JSONB(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
    )


def downgrade() -> None:
    op.drop_table("idempotency_records")
    op.drop_table("payout_authorizations")
    op.drop_table("reviews")
    op.drop_table("validation_findings")
    op.drop_table("validation_runs")
    op.drop_table("submission_assets")
    op.drop_table("submissions")
    op.drop_table("ledger_entries")
    op.drop_table("escrow_campaigns")
    op.drop_table("campaign_requirements")
    op.drop_table("dataset_campaigns")
    op.drop_table("wallet_nonce_challenges")
    op.drop_table("user_wallets")
    op.drop_table("auth_sessions")
    op.drop_table("user_capabilities")
    op.drop_table("user_profiles")
    op.drop_table("users")
