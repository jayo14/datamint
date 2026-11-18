"""Financial reconciliation and blockchain indexing triggers."""

import uuid
from typing import List

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import require_capability
from app.core.database import get_db
from app.models.enums import CapabilityType
from app.models.identity import User
from app.schemas.reconciliation import ReconciliationReport
from app.services.blockchain_indexer import BlockchainIndexerService
from app.services.reconciliation_service import ReconciliationService

router = APIRouter(prefix="/reconciliation", tags=["Financial Reconciliation"])


@router.get(
    "/campaigns/{campaign_id}", response_model=ReconciliationReport, status_code=status.HTTP_200_OK
)
async def reconcile_campaign_ledger(
    campaign_id: uuid.UUID,
    current_user: User = Depends(require_capability(CapabilityType.CREATOR)),
    db: AsyncSession = Depends(get_db),
) -> ReconciliationReport:
    """Audit double-entry ledger invariant and component balance for a specific campaign."""
    service = ReconciliationService(db)
    report = await service.reconcile_campaign(campaign_id)
    return report


@router.get("/campaigns", response_model=List[ReconciliationReport], status_code=status.HTTP_200_OK)
async def reconcile_all_campaigns(
    current_user: User = Depends(require_capability(CapabilityType.ADMIN)),
    db: AsyncSession = Depends(get_db),
) -> List[ReconciliationReport]:
    """Audit financial integrity across all escrow campaigns in the system."""
    service = ReconciliationService(db)
    reports = await service.reconcile_all_campaigns()
    return reports


@router.post("/sync-blockchain", status_code=status.HTTP_200_OK)
async def trigger_blockchain_sync(
    batch_size: int = Query(1000, ge=1, le=5000),
    current_user: User = Depends(require_capability(CapabilityType.ADMIN)),
    db: AsyncSession = Depends(get_db),
) -> dict:
    """Manually trigger Celo smart contract event synchronization and settlement."""
    indexer = BlockchainIndexerService(db)
    indexed_count, last_block = await indexer.sync_events(batch_size=batch_size)
    await db.commit()
    return {"indexed_count": indexed_count, "last_processed_block": last_block}
