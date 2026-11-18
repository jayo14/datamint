"""Phase 3 schema additions: password auth, wallet actions, campaign categories, submission drafts

Revision ID: 0002_phase3_core_workflows
Revises: 0001_initial_schema
Create Date: 2026-11-18 14:00:00.000000

"""
from typing import Sequence, Union

import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

from alembic import op

revision: str = "0002_phase3_core_workflows"
down_revision: Union[str, None] = "0001_initial_schema"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # 1. users: hashed_password, is_verified
    op.add_column("users", sa.Column("hashed_password", sa.String(255), nullable=True))
    op.add_column("users", sa.Column("is_verified", sa.Boolean(), nullable=False, server_default=sa.false()))

    # 2. wallet_nonce_challenges: user_id, action
    op.add_column("wallet_nonce_challenges", sa.Column("user_id", postgresql.UUID(as_uuid=True), nullable=True))
    op.add_column("wallet_nonce_challenges", sa.Column("action", sa.String(50), nullable=False, server_default="login"))
    op.create_foreign_key(
        "fk_wallet_nonce_user_id",
        "wallet_nonce_challenges",
        "users",
        ["user_id"],
        ["id"],
        ondelete="CASCADE",
    )
    op.create_index("ix_wallet_nonce_challenges_user_id", "wallet_nonce_challenges", ["user_id"])

    # 3. dataset_campaigns: category, tags, instructions, eligibility_criteria
    op.add_column("dataset_campaigns", sa.Column("category", sa.String(100), nullable=True))
    op.add_column("dataset_campaigns", sa.Column("tags", postgresql.JSONB(), nullable=True))
    op.add_column("dataset_campaigns", sa.Column("instructions", sa.Text(), nullable=True))
    op.add_column("dataset_campaigns", sa.Column("eligibility_criteria", postgresql.JSONB(), nullable=True))
    op.create_index("ix_dataset_campaigns_category", "dataset_campaigns", ["category"])

    # 4. submissions: draft_data, submitted_at
    op.add_column("submissions", sa.Column("draft_data", postgresql.JSONB(), nullable=True))
    op.add_column("submissions", sa.Column("submitted_at", sa.DateTime(timezone=True), nullable=True))

    # 5. submission_assets: is_uploaded, uploaded_at
    op.add_column("submission_assets", sa.Column("is_uploaded", sa.Boolean(), nullable=False, server_default=sa.false()))
    op.add_column("submission_assets", sa.Column("uploaded_at", sa.DateTime(timezone=True), nullable=True))


def downgrade() -> None:
    op.drop_column("submission_assets", "uploaded_at")
    op.drop_column("submission_assets", "is_uploaded")
    op.drop_column("submissions", "submitted_at")
    op.drop_column("submissions", "draft_data")
    op.drop_index("ix_dataset_campaigns_category", table_name="dataset_campaigns")
    op.drop_column("dataset_campaigns", "eligibility_criteria")
    op.drop_column("dataset_campaigns", "instructions")
    op.drop_column("dataset_campaigns", "tags")
    op.drop_column("dataset_campaigns", "category")
    op.drop_index("ix_wallet_nonce_challenges_user_id", table_name="wallet_nonce_challenges")
    op.drop_constraint("fk_wallet_nonce_user_id", "wallet_nonce_challenges", type_="foreignkey")
    op.drop_column("wallet_nonce_challenges", "action")
    op.drop_column("wallet_nonce_challenges", "user_id")
    op.drop_column("users", "is_verified")
    op.drop_column("users", "hashed_password")
