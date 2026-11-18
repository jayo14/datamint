# DataMint Incident Response & Operational Runbooks

**Document Classification:** RESTRICTED — CORE ENGINEERING & SRE  
**Last Updated:** Phase 6 Production Readiness  
**Target SLAs:** Sev-1 Response < 15 minutes; Sev-2 Response < 1 hour  

---

## 1. Incident Classification & Severity Matrix

| Severity | Definition | Example Scenarios | Escalate To |
| :--- | :--- | :--- | :--- |
| **SEV-1 (Critical)** | Core funds at risk, complete platform outage, suspected private key leak, contract vulnerability | Platform signer compromise, ledger discrepancy, smart contract reentrancy exploit attempt | Lead Architect, Security Officer, On-Call Lead |
| **SEV-2 (Major)** | Core user flow degraded (submissions blocked, RPC desync, indexer halted), DB replica failure | Celo RPC provider down, Celery worker cluster stalled, S3 presigned URL failures | Backend Engineer, DevOps Engineer |
| **SEV-3 (Minor)** | Non-blocking feature degraded (analytics delay, notification delivery lag, minor UI bug) | Redis cache evictions, non-critical AI validation rate limits | Feature Engineer |

---

## 2. Runbook: Suspected Platform Signer Key Compromise (SEV-1)

If unauthorized EIP-712 reward vouchers are observed on-chain or a platform signer key exposure is suspected:

### Step 1: Immediate On-Chain Signer Invalidation
1. Notify multisig signers of the Contract Owner safe.
2. Prepare and execute transaction calling:
   ```solidity
   DatasetEscrow.setPlatformSigner(NEW_SECURE_SIGNER_ADDRESS);
   ```
3. *Effect:* **Immediately and atomically revokes all existing unexecuted vouchers signed by the compromised key.** Any attempt to call `claimReward` with previous vouchers will instantly revert with `InvalidSigner()`.

### Step 2: Invalidate Backend Key Material & Flush Outbox
1. Rotate `PLATFORM_SIGNER_PRIVATE_KEY` in AWS Secrets Manager / Vault / `.env.production`.
2. Stop Celery workers to halt voucher issuance:
   ```bash
   docker-compose -f docker-compose.prod.yml stop celery-worker celery-beat
   ```
3. Expire all pending vouchers in PostgreSQL:
   ```sql
   UPDATE payout_authorizations 
   SET status = 'EXPIRED' 
   WHERE status = 'AUTHORIZED';
   ```

### Step 3: Run Full Financial Reconciliation
1. Execute reconciliation audit across all active escrow campaigns:
   ```bash
   docker-compose -f docker-compose.prod.yml exec backend python -c "
   import asyncio
   from app.core.database import AsyncSessionLocal
   from app.services.reconciliation_service import ReconciliationService
   from sqlalchemy import select
   from app.models.campaign import DatasetCampaign

   async def reconcile_all():
       async with AsyncSessionLocal() as db:
           service = ReconciliationService(db)
           camps = (await db.execute(select(DatasetCampaign))).scalars().all()
           for c in camps:
               report = await service.reconcile_campaign(c.id)
               if not report.is_reconciled:
                   print(f'[ALERT] Campaign {c.id} discrepancy: {report.discrepancies}')
   asyncio.run(reconcile_all())
   "
   ```

### Step 4: Restart Workers with New Key
```bash
docker-compose -f docker-compose.prod.yml up -d --no-deps celery-worker celery-beat
```

---

## 3. Runbook: Celo RPC Provider Outage & Indexer Lag (SEV-2)

If the indexer fails to ingest events due to RPC errors (`HTTP 429`, `502`, or connection drops):

### Step 1: Verify Indexer Sync State Lag
```sql
SELECT 
    chain_id, 
    contract_address, 
    last_processed_block, 
    last_sync_timestamp,
    EXTRACT(EPOCH FROM (NOW() - last_sync_timestamp)) AS lag_seconds
FROM indexer_sync_state;
```

### Step 2: Switch to Fallback RPC Provider
Update `CELO_RPC_URL` in the environment configuration:
- Primary: `https://forno.celo.org`
- Fallback 1: `https://rpc.ankr.com/celo`
- Fallback 2: `https://1rpc.io/celo`
- Fallback 3: Dedicated QuickNode / Alchemy endpoint

Reload backend and worker containers:
```bash
docker-compose -f docker-compose.prod.yml up -d backend celery-worker celery-beat
```

### Step 3: Force Manual Indexer Catch-Up
Trigger synchronous ingestion:
```bash
docker-compose -f docker-compose.prod.yml exec backend python -c "
import asyncio
from app.core.database import AsyncSessionLocal
from app.services.blockchain_indexer import BlockchainIndexerService

async def catch_up():
    async with AsyncSessionLocal() as db:
        indexer = BlockchainIndexerService(db)
        indexed, block = await indexer.sync_events(batch_size=500)
        await db.commit()
        print(f'Synchronized {indexed} events up to block {block}')
asyncio.run(catch_up())
"
```

---

## 4. Runbook: Financial Discrepancy & Reconciliation Alert (SEV-1)

If the hourly reconciliation task flags a discrepancy (`is_reconciled == False`):

### Diagnostic Query
```sql
SELECT 
    c.id AS campaign_id,
    c.title,
    e.total_funded,
    e.total_available,
    e.total_reserved,
    e.total_claimed,
    e.total_refunded,
    (e.total_available + e.total_reserved + e.total_claimed + e.total_refunded) AS component_sum,
    e.total_funded - (e.total_available + e.total_reserved + e.total_claimed + e.total_refunded) AS imbalance
FROM escrow_campaigns e
JOIN dataset_campaigns c ON c.id = e.campaign_id
WHERE e.total_funded != (e.total_available + e.total_reserved + e.total_claimed + e.total_refunded);
```

### Journal Audit
Inspect the chronological double-entry journal for the affected campaign:
```sql
SELECT 
    id, 
    created_at, 
    entry_type, 
    amount, 
    reference_id, 
    notes
FROM ledger_entries
WHERE escrow_campaign_id = (SELECT id FROM escrow_campaigns WHERE campaign_id = '<CAMPAIGN_UUID>')
ORDER BY created_at ASC;
```

If an orphaned chain reorg or unhandled out-of-order event created the mismatch, issue an explicit compensating journal entry using `LedgerService.record_journal_entry` with administrative notes. **Never directly modify SQL row totals without a corresponding ledger entry.**
