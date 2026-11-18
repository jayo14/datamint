"""Pydantic schemas for financial reconciliation reports."""

import uuid
from datetime import datetime
from decimal import Decimal
from typing import List, Optional

from pydantic import BaseModel, ConfigDict


class ReconciliationReport(BaseModel):
    """Detailed reconciliation breakdown comparing double-entry ledger state with on-chain escrow."""

    model_config = ConfigDict(from_attributes=True)

    campaign_id: uuid.UUID
    onchain_campaign_id: Optional[str] = None
    is_reconciled: bool
    invariant_holds: bool
    total_funded: Decimal
    total_available: Decimal
    total_reserved: Decimal
    total_claimed: Decimal
    total_refunded: Decimal
    onchain_claimed_amount: Optional[Decimal] = None
    onchain_refunded_amount: Optional[Decimal] = None
    discrepancies: List[str] = []
    timestamp: datetime
