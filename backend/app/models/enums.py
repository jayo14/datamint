"""Database and domain enumerations."""

import enum


class CapabilityType(str, enum.Enum):
    CONTRIBUTOR = "CONTRIBUTOR"
    CREATOR = "CREATOR"
    REVIEWER = "REVIEWER"
    ADMIN = "ADMIN"


class DataType(str, enum.Enum):
    TEXT = "TEXT"
    VOICE = "VOICE"
    IMAGE = "IMAGE"


class CampaignStatus(str, enum.Enum):
    DRAFT = "DRAFT"
    PENDING_FUNDING = "PENDING_FUNDING"
    ACTIVE = "ACTIVE"
    PAUSED = "PAUSED"
    COMPLETED = "COMPLETED"
    EXPIRED = "EXPIRED"
    CANCELLED = "CANCELLED"


class SubmissionStatus(str, enum.Enum):
    PENDING_UPLOAD = "PENDING_UPLOAD"
    UPLOAD_FAILED = "UPLOAD_FAILED"
    QUEUED_FOR_VALIDATION = "QUEUED_FOR_VALIDATION"
    VALIDATING = "VALIDATING"
    APPROVED = "APPROVED"
    NEEDS_REVIEW = "NEEDS_REVIEW"
    REJECTED = "REJECTED"
    UNDER_APPEAL = "UNDER_APPEAL"
    SETTLED = "SETTLED"


class AssetType(str, enum.Enum):
    AUDIO = "AUDIO"
    IMAGE = "IMAGE"
    TEXT = "TEXT"
    METADATA = "METADATA"


class ValidationStatus(str, enum.Enum):
    PENDING = "PENDING"
    PASSED = "PASSED"
    FAILED = "FAILED"
    FLAGGED = "FLAGGED"


class LedgerEntryType(str, enum.Enum):
    DEPOSIT = "DEPOSIT"
    RESERVATION = "RESERVATION"
    UNRESERVATION = "UNRESERVATION"
    CLAIM = "CLAIM"
    REFUND = "REFUND"


class PayoutStatus(str, enum.Enum):
    AUTHORIZED = "AUTHORIZED"
    CLAIMED = "CLAIMED"
    EXPIRED = "EXPIRED"
    REVOKED = "REVOKED"
