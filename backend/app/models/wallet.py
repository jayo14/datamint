"""User-owned wallet connections and cryptographic challenge nonces."""

import uuid
from datetime import datetime, timezone
from typing import TYPE_CHECKING

from sqlalchemy import Boolean, DateTime, ForeignKey, Integer, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.models.identity import UuidType

if TYPE_CHECKING:
    from app.models.identity import User


class Wallet(Base):
    __tablename__ = "user_wallets"

    id: Mapped[uuid.UUID] = mapped_column(
        UuidType,
        primary_key=True,
        default=uuid.uuid4,
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        UuidType,
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    # Stored lowercased for case-insensitive Ethereum/Celo comparisons
    address: Mapped[str] = mapped_column(String(42), unique=True, nullable=False, index=True)
    chain_id: Mapped[int] = mapped_column(Integer, default=42220, nullable=False)
    is_primary: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    verified_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=False,
    )

    user: Mapped["User"] = relationship("User", back_populates="wallets")


class WalletNonceChallenge(Base):
    """Temporary nonce challenge for EIP-4361 authentication."""

    __tablename__ = "wallet_nonce_challenges"

    id: Mapped[uuid.UUID] = mapped_column(
        UuidType,
        primary_key=True,
        default=uuid.uuid4,
    )
    address: Mapped[str] = mapped_column(String(42), nullable=False, index=True)
    nonce: Mapped[str] = mapped_column(String(64), unique=True, nullable=False, index=True)
    chain_id: Mapped[int] = mapped_column(Integer, default=42220, nullable=False)
    is_used: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=False,
    )
