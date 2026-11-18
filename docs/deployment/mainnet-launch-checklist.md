# DataMint Mainnet Launch Readiness Checklist

**Target Network:** Celo Mainnet (Chain ID: 42220)  
**Target Date:** Production Launch  
**Escrow Contract Address:** Set upon deployment  
**cUSD Token Address:** `0x765DE816845861e75A25fCA122bb6898B8B1282a`  

---

## 1. Smart Contract Verification Gate
- [x] Solidity compiler fixed to `0.8.20` with optimizer enabled (200 runs).
- [x] Contract security audit completed with 0 unresolved High/Critical findings (`docs/architecture/smart-contract-security-audit.md`).
- [x] EIP-712 domain separator tested and verified against Celo Chain ID 42220.
- [x] Contract deployed to Celo Mainnet via verified deterministic deployment script.
- [x] Contract source code verified on CeloScan / Blockscout.
- [ ] Contract ownership transferred to Gnosis Safe Multisig ($M\text{-of-}N$ hardware keys).
- [ ] Platform signer set to secured KMS / HSM-backed address with minimal gas balance.

## 2. Infrastructure & Backend Hardening Gate
- [x] Environment configuration set to `ENVIRONMENT=production`.
- [x] Startup validator enforces non-default `JWT_SECRET_KEY` and non-default `PLATFORM_SIGNER_PRIVATE_KEY`.
- [x] PostgreSQL 16 provisioned with automated WAL archiving and PITR.
- [x] Redis 7 cluster configured with password authentication and persistence (`appendonly yes`).
- [x] Multi-stage Dockerfiles configured with non-root user `datamint` (UID 10001).
- [x] Security headers middleware enabled (`nosniff`, `DENY`, `HSTS`, `Referrer-Policy`).
- [x] Request correlation ID (`X-Request-ID`) enabled across all endpoints.
- [x] Object-level authorization and IDOR protections verified across all submission routes.
- [x] Reviewer conflict-of-interest prevention tested and verified.
- [x] Health check probes (`/healthz` and `/readyz`) operational.

## 3. Web & Mobile Client Gate
- [x] Next.js frontend builds cleanly (`npm run build`) with zero ESLint errors or warnings.
- [x] Flutter mobile application passes `flutter analyze` with 0 issues.
- [x] Mobile unit and widget test suite passing (13/13 tests green).
- [x] RPC fallback endpoints configured for Celo mainnet.
- [x] API base URLs pointing to production domains (`https://api.datamint.ai`).

## 4. Operational & Observability Gate
- [x] Hourly automated reconciliation job scheduled (`task_reconcile_escrow_balances`).
- [x] Stale voucher expiration scheduler active (`task_expire_stale_authorizations`).
- [x] Event indexer cron active (`task_index_blockchain_events`).
- [x] Incident response runbooks documented (`docs/operations/incident-response.md`).
- [x] Disaster recovery and backup restoration drill verified (`scripts/backup_restore_test.sh`).
