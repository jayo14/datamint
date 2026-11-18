"""SQLAlchemy models registry."""

from app.models.campaign import (
    CampaignRequirement,
    DatasetCampaign,
)
from app.models.enums import (
    AssetType,
    CampaignStatus,
    CapabilityType,
    DataType,
    LedgerEntryType,
    PayoutStatus,
    SubmissionStatus,
    ValidationStatus,
)
from app.models.financial import (
    EscrowCampaign,
    IdempotencyRecord,
    LedgerEntry,
    PayoutAuthorization,
)
from app.models.identity import (
    AuthSession,
    User,
    UserCapability,
    UserProfile,
)
from app.models.submission import (
    Review,
    Submission,
    SubmissionAsset,
    ValidationFinding,
    ValidationRun,
)
from app.models.wallet import (
    Wallet,
    WalletNonceChallenge,
)

__all__ = [
    "CapabilityType",
    "DataType",
    "CampaignStatus",
    "SubmissionStatus",
    "AssetType",
    "ValidationStatus",
    "LedgerEntryType",
    "PayoutStatus",
    "User",
    "UserProfile",
    "UserCapability",
    "AuthSession",
    "Wallet",
    "WalletNonceChallenge",
    "DatasetCampaign",
    "CampaignRequirement",
    "Submission",
    "SubmissionAsset",
    "ValidationRun",
    "ValidationFinding",
    "Review",
    "EscrowCampaign",
    "LedgerEntry",
    "PayoutAuthorization",
    "IdempotencyRecord",
]
