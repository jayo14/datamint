"""Financial escrow balances, double-entry ledger entries, payout vouchers, and idempotency."""

import uuid
from datetime import datetime, timezone
from decimal import Decimal
from typing import TYPE_CHECKING, List, Optional

from sqlalchemy import (
    BigInteger,
    Boolean,
    CheckConstraint,
    DateTime,
    ForeignKey,
    Index,
    Integer,
    Numeric,
    String,
    Text,
    UniqueConstraint,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.models.enums import LedgerEntryType, PayoutStatus
from app.models.identity import JsonType, UuidType

if TYPE_CHECKING:
    from app.models.campaign import DatasetCampaign
    from app.models.submission import Submission


class EscrowCampaign(Base):
    """Campaign escrow ledger summary enforcing non-negative balances and the financial invariant."""

    __tablename__ = "escrow_campaigns"
    __table_args__ = (
        CheckConstraint("total_funded >= 0", name="chk_escrow_funded_non_negative"),
        CheckConstraint("total_claimed >= 0", name="chk_escrow_claimed_non_negative"),
        CheckConstraint("total_reserved >= 0", name="chk_escrow_reserved_non_negative"),
        CheckConstraint("total_available >= 0", name="chk_escrow_available_non_negative"),
        CheckConstraint("total_refunded >= 0", name="chk_escrow_refunded_non_negative"),
    )

    id: Mapped[uuid.UUID] = mapped_column(
        UuidType,
        primary_key=True,
        default=uuid.uuid4,
    )
    campaign_id: Mapped[uuid.UUID] = mapped_column(
        UuidType,
        ForeignKey("dataset_campaigns.id", ondelete="RESTRICT"),
        unique=True,
        nullable=False,
    )
    onchain_campaign_id: Mapped[Optional[str]] = mapped_column(
        String(100), unique=True, nullable=True, index=True
    )
    total_funded: Mapped[Decimal] = mapped_column(
        Numeric(24, 6), default=Decimal("0.0"), nullable=False
    )
    total_claimed: Mapped[Decimal] = mapped_column(
        Numeric(24, 6), default=Decimal("0.0"), nullable=False
    )
    total_reserved: Mapped[Decimal] = mapped_column(
        Numeric(24, 6), default=Decimal("0.0"), nullable=False
    )
    total_available: Mapped[Decimal] = mapped_column(
        Numeric(24, 6), default=Decimal("0.0"), nullable=False
    )
    total_refunded: Mapped[Decimal] = mapped_column(
        Numeric(24, 6), default=Decimal("0.0"), nullable=False
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=False,
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
        nullable=False,
    )

    # Relationships
    campaign: Mapped["DatasetCampaign"] = relationship("DatasetCampaign", back_populates="escrow")
    ledger_entries: Mapped[List["LedgerEntry"]] = relationship(
        "LedgerEntry", back_populates="escrow", cascade="all, delete-orphan"
    )

    def check_invariant(self) -> bool:
        """Validate the core invariant: Funded == Claimed + Reserved + Available + Refunded."""
        return self.total_funded == (
            self.total_claimed + self.total_reserved + self.total_available + self.total_refunded
        )


class LedgerEntry(Base):
    """Immutable double-entry journal entry for campaign escrow."""

    __tablename__ = "ledger_entries"
    __table_args__ = (
        CheckConstraint("amount > 0", name="chk_ledger_amount_positive"),
        Index("ix_ledger_escrow_created", "escrow_campaign_id", "created_at"),
    )

    id: Mapped[uuid.UUID] = mapped_column(
        UuidType,
        primary_key=True,
        default=uuid.uuid4,
    )
    escrow_campaign_id: Mapped[uuid.UUID] = mapped_column(
        UuidType,
        ForeignKey("escrow_campaigns.id", ondelete="RESTRICT"),
        nullable=False,
        index=True,
    )
    entry_type: Mapped[str] = mapped_column(
        String(50),
        default=LedgerEntryType.DEPOSIT.value,
        nullable=False,
    )
    amount: Mapped[Decimal] = mapped_column(Numeric(24, 6), nullable=False)
    running_available: Mapped[Decimal] = mapped_column(Numeric(24, 6), nullable=False)
    running_reserved: Mapped[Decimal] = mapped_column(Numeric(24, 6), nullable=False)
    running_claimed: Mapped[Decimal] = mapped_column(Numeric(24, 6), nullable=False)
    running_refunded: Mapped[Decimal] = mapped_column(Numeric(24, 6), nullable=False)
    reference_id: Mapped[str] = mapped_column(String(200), unique=True, nullable=False, index=True)
    notes: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=False,
    )

    escrow: Mapped["EscrowCampaign"] = relationship(
        "EscrowCampaign", back_populates="ledger_entries"
    )


class PayoutAuthorization(Base):
    """Signed EIP-712 payout authorization voucher."""

    __tablename__ = "payout_authorizations"

    id: Mapped[uuid.UUID] = mapped_column(
        UuidType,
        primary_key=True,
        default=uuid.uuid4,
    )
    submission_id: Mapped[uuid.UUID] = mapped_column(
        UuidType,
        ForeignKey("submissions.id", ondelete="RESTRICT"),
        unique=True,
        nullable=False,
    )
    contributor_id: Mapped[uuid.UUID] = mapped_column(
        UuidType,
        ForeignKey("users.id", ondelete="RESTRICT"),
        nullable=False,
        index=True,
    )
    amount: Mapped[Decimal] = mapped_column(Numeric(24, 6), nullable=False)
    recipient_address: Mapped[str] = mapped_column(String(42), nullable=False, index=True)
    nonce: Mapped[Optional[str]] = mapped_column(String(66), unique=True, nullable=True, index=True)
    onchain_campaign_id: Mapped[Optional[str]] = mapped_column(
        String(66), nullable=True, index=True
    )
    deadline: Mapped[Optional[int]] = mapped_column(BigInteger, nullable=True)
    voucher_hash: Mapped[str] = mapped_column(String(66), unique=True, nullable=False, index=True)
    signature: Mapped[str] = mapped_column(String(132), nullable=False)
    claim_tx_hash: Mapped[Optional[str]] = mapped_column(String(66), nullable=True, index=True)
    claimed_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
    status: Mapped[str] = mapped_column(
        String(50),
        default=PayoutStatus.AUTHORIZED.value,
        nullable=False,
        index=True,
    )
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=False,
    )

    submission: Mapped["Submission"] = relationship(
        "Submission", back_populates="payout_authorization"
    )


class BlockchainEvent(Base):
    """Indexed Celo smart contract events with deduplication and reorg protection."""

    __tablename__ = "blockchain_events"
    __table_args__ = (
        UniqueConstraint("transaction_hash", "log_index", name="uq_blockchain_events_tx_log"),
        Index("ix_blockchain_events_name_block", "event_name", "block_number"),
    )

    id: Mapped[uuid.UUID] = mapped_column(
        UuidType,
        primary_key=True,
        default=uuid.uuid4,
    )
    chain_id: Mapped[int] = mapped_column(Integer, nullable=False, index=True)
    contract_address: Mapped[str] = mapped_column(String(42), nullable=False, index=True)
    event_name: Mapped[str] = mapped_column(String(100), nullable=False, index=True)
    transaction_hash: Mapped[str] = mapped_column(String(66), nullable=False, index=True)
    block_number: Mapped[int] = mapped_column(BigInteger, nullable=False, index=True)
    block_hash: Mapped[str] = mapped_column(String(66), nullable=False)
    log_index: Mapped[int] = mapped_column(Integer, nullable=False)
    parameters: Mapped[dict] = mapped_column(JsonType, nullable=False)
    is_confirmed: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    confirmations: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    status: Mapped[str] = mapped_column(
        String(50),
        default="INDEXED",
        nullable=False,
        index=True,
    )
    processed_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=False,
    )


class IndexerSyncState(Base):
    """Checkpoint of last indexed block height per contract and chain."""

    __tablename__ = "indexer_sync_state"

    id: Mapped[uuid.UUID] = mapped_column(
        UuidType,
        primary_key=True,
        default=uuid.uuid4,
    )
    chain_id: Mapped[int] = mapped_column(Integer, nullable=False, unique=True)
    contract_address: Mapped[str] = mapped_column(String(42), nullable=False)
    last_processed_block: Mapped[int] = mapped_column(BigInteger, default=0, nullable=False)
    last_sync_timestamp: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=False,
    )


class IdempotencyRecord(Base):
    """Global deduplication table for API requests and blockchain events."""

    __tablename__ = "idempotency_records"

    id: Mapped[uuid.UUID] = mapped_column(
        UuidType,
        primary_key=True,
        default=uuid.uuid4,
    )
    key: Mapped[str] = mapped_column(String(255), unique=True, nullable=False, index=True)
    scope: Mapped[str] = mapped_column(String(100), nullable=False)
    response_payload: Mapped[Optional[dict]] = mapped_column(JsonType, nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=False,
    )
