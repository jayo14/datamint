"""Dataset campaigns, requirements, and reward configurations."""

import uuid
from datetime import datetime, timezone
from decimal import Decimal
from typing import TYPE_CHECKING, List, Optional

from sqlalchemy import (
    CheckConstraint,
    DateTime,
    ForeignKey,
    Index,
    Integer,
    Numeric,
    String,
    Text,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.models.enums import CampaignStatus, DataType
from app.models.identity import JsonType, UuidType

if TYPE_CHECKING:
    from app.models.financial import EscrowCampaign
    from app.models.identity import User
    from app.models.submission import Submission


class DatasetCampaign(Base):
    __tablename__ = "dataset_campaigns"
    __table_args__ = (
        CheckConstraint("target_submissions > 0", name="chk_target_submissions_positive"),
        CheckConstraint("current_submissions >= 0", name="chk_current_submissions_non_negative"),
        CheckConstraint("reward_per_submission > 0", name="chk_reward_per_submission_positive"),
        Index("ix_campaigns_status_created", "status", "created_at"),
    )

    id: Mapped[uuid.UUID] = mapped_column(
        UuidType,
        primary_key=True,
        default=uuid.uuid4,
    )
    creator_id: Mapped[uuid.UUID] = mapped_column(
        UuidType,
        ForeignKey("users.id", ondelete="RESTRICT"),
        nullable=False,
        index=True,
    )
    title: Mapped[str] = mapped_column(String(200), nullable=False)
    description: Mapped[str] = mapped_column(Text, nullable=False)
    data_type: Mapped[str] = mapped_column(
        String(50),
        default=DataType.TEXT.value,
        nullable=False,
        index=True,
    )
    status: Mapped[str] = mapped_column(
        String(50),
        default=CampaignStatus.DRAFT.value,
        nullable=False,
        index=True,
    )
    target_submissions: Mapped[int] = mapped_column(Integer, nullable=False)
    current_submissions: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    reward_per_submission: Mapped[Decimal] = mapped_column(
        Numeric(18, 4),
        nullable=False,
    )
    reward_currency: Mapped[str] = mapped_column(String(10), default="cUSD", nullable=False)
    category: Mapped[Optional[str]] = mapped_column(String(100), nullable=True, index=True)
    tags: Mapped[Optional[list]] = mapped_column(JsonType, nullable=True)
    instructions: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    eligibility_criteria: Mapped[Optional[dict]] = mapped_column(JsonType, nullable=True)
    deadline: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
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
    creator: Mapped["User"] = relationship("User", back_populates="campaigns")
    requirements: Mapped[Optional["CampaignRequirement"]] = relationship(
        "CampaignRequirement",
        back_populates="campaign",
        uselist=False,
        cascade="all, delete-orphan",
    )
    escrow: Mapped[Optional["EscrowCampaign"]] = relationship(
        "EscrowCampaign",
        back_populates="campaign",
        uselist=False,
        cascade="all, delete-orphan",
    )
    submissions: Mapped[List["Submission"]] = relationship("Submission", back_populates="campaign")


class CampaignRequirement(Base):
    __tablename__ = "campaign_requirements"

    id: Mapped[uuid.UUID] = mapped_column(
        UuidType,
        primary_key=True,
        default=uuid.uuid4,
    )
    campaign_id: Mapped[uuid.UUID] = mapped_column(
        UuidType,
        ForeignKey("dataset_campaigns.id", ondelete="CASCADE"),
        unique=True,
        nullable=False,
    )
    validation_rules: Mapped[Optional[dict]] = mapped_column(JsonType, nullable=True)
    min_duration_sec: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    max_duration_sec: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    instructions: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    criteria_metadata: Mapped[Optional[dict]] = mapped_column(JsonType, nullable=True)

    campaign: Mapped["DatasetCampaign"] = relationship(
        "DatasetCampaign", back_populates="requirements"
    )
