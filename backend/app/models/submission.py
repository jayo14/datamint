"""Submissions, media assets, AI validation runs, and review appeals."""

import uuid
from datetime import datetime, timezone
from decimal import Decimal
from typing import TYPE_CHECKING, List, Optional

from sqlalchemy import (
    BigInteger,
    Boolean,
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
from app.models.enums import AppealStatus, AssetType, SubmissionStatus, ValidationStatus
from app.models.identity import JsonType, UuidType

if TYPE_CHECKING:
    from app.models.campaign import DatasetCampaign
    from app.models.financial import PayoutAuthorization
    from app.models.identity import User


class Submission(Base):
    __tablename__ = "submissions"
    __table_args__ = (
        Index("ix_submissions_campaign_status", "campaign_id", "status"),
        Index("ix_submissions_contributor_created", "contributor_id", "created_at"),
    )

    id: Mapped[uuid.UUID] = mapped_column(
        UuidType,
        primary_key=True,
        default=uuid.uuid4,
    )
    campaign_id: Mapped[uuid.UUID] = mapped_column(
        UuidType,
        ForeignKey("dataset_campaigns.id", ondelete="RESTRICT"),
        nullable=False,
    )
    contributor_id: Mapped[uuid.UUID] = mapped_column(
        UuidType,
        ForeignKey("users.id", ondelete="RESTRICT"),
        nullable=False,
    )
    status: Mapped[str] = mapped_column(
        String(50),
        default=SubmissionStatus.PENDING_UPLOAD.value,
        nullable=False,
        index=True,
    )
    attempt_number: Mapped[int] = mapped_column(Integer, default=1, nullable=False)
    draft_data: Mapped[Optional[dict]] = mapped_column(JsonType, nullable=True)
    metadata_json: Mapped[Optional[dict]] = mapped_column(JsonType, nullable=True)
    submitted_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
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
    campaign: Mapped["DatasetCampaign"] = relationship(
        "DatasetCampaign", back_populates="submissions"
    )
    contributor: Mapped["User"] = relationship("User", back_populates="submissions")
    assets: Mapped[List["SubmissionAsset"]] = relationship(
        "SubmissionAsset", back_populates="submission", cascade="all, delete-orphan"
    )
    validation_runs: Mapped[List["ValidationRun"]] = relationship(
        "ValidationRun", back_populates="submission", cascade="all, delete-orphan"
    )
    reviews: Mapped[List["Review"]] = relationship(
        "Review", back_populates="submission", cascade="all, delete-orphan"
    )
    appeals: Mapped[List["Appeal"]] = relationship(
        "Appeal", back_populates="submission", cascade="all, delete-orphan"
    )
    payout_authorization: Mapped[Optional["PayoutAuthorization"]] = relationship(
        "PayoutAuthorization",
        back_populates="submission",
        uselist=False,
        cascade="all, delete-orphan",
    )


class SubmissionAsset(Base):
    __tablename__ = "submission_assets"

    id: Mapped[uuid.UUID] = mapped_column(
        UuidType,
        primary_key=True,
        default=uuid.uuid4,
    )
    submission_id: Mapped[uuid.UUID] = mapped_column(
        UuidType,
        ForeignKey("submissions.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    asset_type: Mapped[str] = mapped_column(
        String(50),
        default=AssetType.AUDIO.value,
        nullable=False,
    )
    storage_key: Mapped[str] = mapped_column(String(500), unique=True, nullable=False)
    byte_size: Mapped[int] = mapped_column(BigInteger, nullable=False)
    mime_type: Mapped[str] = mapped_column(String(100), nullable=False)
    checksum_sha256: Mapped[Optional[str]] = mapped_column(String(64), nullable=True)
    is_uploaded: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    uploaded_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=False,
    )

    submission: Mapped["Submission"] = relationship("Submission", back_populates="assets")


class ValidationRun(Base):
    __tablename__ = "validation_runs"

    id: Mapped[uuid.UUID] = mapped_column(
        UuidType,
        primary_key=True,
        default=uuid.uuid4,
    )
    submission_id: Mapped[uuid.UUID] = mapped_column(
        UuidType,
        ForeignKey("submissions.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    validator_type: Mapped[str] = mapped_column(String(100), nullable=False)
    ai_provider: Mapped[Optional[str]] = mapped_column(String(50), nullable=True)
    model_version: Mapped[Optional[str]] = mapped_column(String(50), nullable=True)
    policy_version: Mapped[str] = mapped_column(String(20), default="1.0", nullable=False)
    status: Mapped[str] = mapped_column(
        String(50),
        default=ValidationStatus.PENDING.value,
        nullable=False,
    )
    score: Mapped[Optional[Decimal]] = mapped_column(Numeric(5, 4), nullable=True)
    execution_duration_ms: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    failure_reason: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    raw_output: Mapped[Optional[dict]] = mapped_column(JsonType, nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=False,
    )
    completed_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)

    submission: Mapped["Submission"] = relationship("Submission", back_populates="validation_runs")
    findings: Mapped[List["ValidationFinding"]] = relationship(
        "ValidationFinding", back_populates="validation_run", cascade="all, delete-orphan"
    )


class ValidationFinding(Base):
    __tablename__ = "validation_findings"

    id: Mapped[uuid.UUID] = mapped_column(
        UuidType,
        primary_key=True,
        default=uuid.uuid4,
    )
    validation_run_id: Mapped[uuid.UUID] = mapped_column(
        UuidType,
        ForeignKey("validation_runs.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    code: Mapped[str] = mapped_column(String(100), nullable=False)
    severity: Mapped[str] = mapped_column(String(20), default="INFO", nullable=False)
    message: Mapped[str] = mapped_column(Text, nullable=False)
    is_deterministic: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    evidence: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    details: Mapped[Optional[dict]] = mapped_column(JsonType, nullable=True)

    validation_run: Mapped["ValidationRun"] = relationship(
        "ValidationRun", back_populates="findings"
    )


class Review(Base):
    __tablename__ = "reviews"

    id: Mapped[uuid.UUID] = mapped_column(
        UuidType,
        primary_key=True,
        default=uuid.uuid4,
    )
    submission_id: Mapped[uuid.UUID] = mapped_column(
        UuidType,
        ForeignKey("submissions.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    reviewer_id: Mapped[uuid.UUID] = mapped_column(
        UuidType,
        ForeignKey("users.id", ondelete="RESTRICT"),
        nullable=False,
    )
    review_type: Mapped[str] = mapped_column(
        String(50), default="MANUAL_VALIDATION", nullable=False
    )
    decision: Mapped[str] = mapped_column(String(50), nullable=False)
    notes: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    rejection_reason: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
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

    submission: Mapped["Submission"] = relationship("Submission", back_populates="reviews")
    reviewer: Mapped["User"] = relationship("User")


class Appeal(Base):
    __tablename__ = "appeals"

    id: Mapped[uuid.UUID] = mapped_column(
        UuidType,
        primary_key=True,
        default=uuid.uuid4,
    )
    submission_id: Mapped[uuid.UUID] = mapped_column(
        UuidType,
        ForeignKey("submissions.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    contributor_id: Mapped[uuid.UUID] = mapped_column(
        UuidType,
        ForeignKey("users.id", ondelete="RESTRICT"),
        nullable=False,
        index=True,
    )
    reason: Mapped[str] = mapped_column(Text, nullable=False)
    evidence: Mapped[Optional[dict]] = mapped_column(JsonType, nullable=True)
    status: Mapped[str] = mapped_column(
        String(50),
        default=AppealStatus.PENDING.value,
        nullable=False,
        index=True,
    )
    reviewer_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        UuidType,
        ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True,
    )
    reviewer_notes: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    resolved_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=False,
    )

    submission: Mapped["Submission"] = relationship("Submission", back_populates="appeals")
    contributor: Mapped["User"] = relationship("User", foreign_keys=[contributor_id])
    reviewer: Mapped[Optional["User"]] = relationship("User", foreign_keys=[reviewer_id])
