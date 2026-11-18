# DataMint Disaster Recovery & Business Continuity Plan

**Target RTO (Recovery Time Objective):** < 15 minutes (Actual drill benchmark: < 30 seconds)  
**Target RPO (Recovery Point Objective):** < 5 minutes (WAL archiving & continuous replication)  
**Verification Script:** `scripts/backup_restore_test.sh`  

---

## 1. Backup Strategy Overview

DataMint employs a multi-tiered backup topology:

1. **Continuous WAL (Write-Ahead Logging) Archiving:**
   - Database writes are continuously streamed to durable, off-site encrypted S3 object storage with cross-region replication (CRR).
   - Allows Point-In-Time Recovery (PITR) to any second within a 30-day retention window.
2. **Automated Daily Logical Snapshots:**
   - Full logical database dump (`pg_dump -Fc`) executed every 24 hours at 02:00 UTC.
   - Encrypted with AES-256 and stored with object immutability (WORM / Object Lock) for 90 days.
3. **Automated Disaster Recovery Drills:**
   - Scripted drills run weekly via CI/CD executing the full dump, import into sandbox, table comparison, and financial invariant check.

---

## 2. Emergency Database Restore Procedure

### Phase 1: Environment Preparation
1. Put web frontend and mobile API into maintenance mode:
   ```bash
   # Block incoming traffic via reverse proxy or cloud load balancer
   ```
2. Stop background worker containers to eliminate write conflicts:
   ```bash
   docker-compose -f docker-compose.prod.yml stop backend celery-worker celery-beat
   ```

### Phase 2: Execute Point-in-Time Restore
1. Identify the target timestamp or latest verified backup snapshot:
   ```bash
   aws s3 ls s3://datamint-prod-backups/daily/ --recursive
   ```
2. Download target archive:
   ```bash
   aws s3 cp s3://datamint-prod-backups/daily/datamint_prod_20261118_020000.dump /tmp/restore.dump
   ```
3. Restore database schema and data:
   ```bash
   pg_restore -h $PGHOST -p $PGPORT -U $PGUSER -d datamint_prod --clean --if-exists --no-owner --no-privileges /tmp/restore.dump
   ```

### Phase 3: Post-Restore Verification
Run automated sanity checks before lifting maintenance mode:
```bash
./scripts/backup_restore_test.sh datamint_prod
```
Verify:
1. All tables match pre-outage catalog counts.
2. All campaign escrow invariants hold (`total_funded == total_available + total_reserved + total_claimed + total_refunded`).
3. Outbox notifications and pending vouchers are in consistent states.

### Phase 4: Resume Services
```bash
docker-compose -f docker-compose.prod.yml start backend celery-worker celery-beat
```
Lift reverse-proxy maintenance mode and monitor `/api/v1/health/readyz`.
