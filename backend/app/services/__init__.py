"""Services registry."""

from app.services.auth_service import AuthService
from app.services.campaign_service import CampaignService
from app.services.ledger_service import LedgerService
from app.services.submission_service import SubmissionService

__all__ = [
    "AuthService",
    "CampaignService",
    "LedgerService",
    "SubmissionService",
]
