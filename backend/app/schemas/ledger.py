"""Financial ledger and payout authorization schemas."""

import uuid
from datetime import datetime
from decimal import Decimal
from typing import Optional

from app.models.enums import LedgerEntryType, PayoutStatus
from app.schemas.common import BaseSchema


class LedgerEntryResponse(BaseSchema):
    id: uuid.UUID
    escrow_campaign_id: uuid.UUID
    entry_type: LedgerEntryType
    amount: Decimal
    running_available: Decimal
    running_reserved: Decimal
    running_claimed: Decimal
    running_refunded: Decimal
    reference_id: str
    notes: Optional[str] = None
    created_at: datetime


class PayoutVoucherResponse(BaseSchema):
    id: uuid.UUID
    submission_id: uuid.UUID
    amount: Decimal
    recipient_address: str
    voucher_hash: str
    signature: str
    status: PayoutStatus
    expires_at: datetime
    created_at: datetime
