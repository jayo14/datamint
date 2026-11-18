# Pre-Mainnet Security and Operational Validation Plan

**Current Status:** PRODUCTION CANDIDATE  
**Mainnet Deployment Gate:** **BLOCKED** (Pending independent verification of all 9 gates)  
**Target Milestone:** Pre-Mainnet Security and Operational Validation  
**Target Blockchain Testnet:** Celo Sepolia (Chain ID: `11142220`)  
**Target Mainnet:** Celo Mainnet (Chain ID: `42220`)  

---

## 1. Executive Summary & Philosophy

DataMint has transitioned from feature engineering into formal production engineering. Because DataMint is a decentralized dataset marketplace handling user funds and private datasets, **mainnet deployment is explicitly gated**. 

Passing internal tests and automated CI confirms repeatability and structural correctness; it does not constitute independent proof of financial safety. Mainnet deployment will only be approved once all 5 core deliverables are independently evidenced and signed off under the **DataMint Mainnet Go/No-Go Gate**.

---

## 2. Five Pre-Mainnet Deliverables & Evidence Matrix

| Deliverable | Objective | Evidence Required Before Sign-Off | Responsible Owners |
| :--- | :--- | :--- | :--- |
| **1. Independent Contract Audit** | Third-party professional security review of escrow contracts. | Published external audit report from accredited firm; all High/Critical findings remediated and verified; compiler & artifact hash frozen. | Lead Blockchain Architect, External Auditor |
| **2. Celo Sepolia Financial Journey** | Full end-to-end lifecycle verification on live public testnet. | On-chain deployment to Celo Sepolia (11142220); real cUSD transactions (creation, funding, EIP-712 claims, cancellation, refund); 0 balance discrepancies across smart contract and database ledger. | Backend Lead, QA Engineer |
| **3. Key Management Review** | HSM/KMS voucher signing and 3-of-5 Safe governance verification. | AWS KMS DER-to-EVM `(r, s, v)` automated tests; 3-of-5 Gnosis Safe ownership transfer drill; signer rotation and emergency revocation dry-run. | Security Lead, DevOps |
| **4. Disaster Recovery (WAL/PITR)** | Measurable proof of data durability and disaster recovery limits. | Executed PITR drill (`scripts/wal_pitr_drill.py`) proving RPO < 5 minutes, RTO < 15 minutes; uncommitted transaction rollback verification; 0 balance conservation violations. | Database Administrator, SRE |
| **5. Final Operational Readiness** | End-to-end organizational, regulatory, and system readiness. | All 4 CI pipelines green; signed Go/No-Go authorization by executive stakeholders; incident response runbooks drilled; production secrets rotated. | CTO, Head of Product, Compliance |

---

## 3. Deliverable 1: Smart Contract Audit Freeze Specification

To prevent discrepancy between audited code and deployed bytecode, the auditor will review a strictly frozen deployable artifact:

- **Target Contract:** `contracts/src/DatasetEscrow.sol` and interfaces.
- **Git Commit Hash:** Frozen at audit cutoff commit.
- **Solidity Compiler Version:** `0.8.24` (via `solc`).
- **EVM Target:** `cancun`.
- **Optimizer Settings:** `optimizer = true`, `runs = 200`.
- **OpenZeppelin Contracts Version:** `@openzeppelin/contracts@5.0.2`.
- **Verification Invariant:**
  $$\text{Contract cUSD Balance} = \sum \text{Total Funded} - \sum \text{Total Claimed} - \sum \text{Total Refunded}$$
  $$\forall \text{ campaigns: } \text{claimedAmount} \le \text{totalBudget} \land \text{claimedCount} \le \text{maxSubmissions}$$

---

## 4. Deliverable 2: Celo Sepolia Testnet End-to-End Financial Journey

Celo Alfajores was officially deprecated in September 2025. All pre-mainnet testnet operations execute exclusively on **Celo Sepolia**:

- **Network Name:** Celo Sepolia Testnet
- **Chain ID:** `11142220`
- **RPC URL:** `https://forno.celo-sepolia.celo-testnet.org`
- **Block Explorer:** `https://sepolia.celoscan.io`
- **cUSD Testnet Address:** `0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1`

### Execution Test Matrix:
1. **Campaign Creation & Funding:** Creator funds campaign with 100 test cUSD. Verified on Sepolia block explorer.
2. **AI Submission & Approval:** Contributor submits dataset; validation pipeline executes; reviewer approves.
3. **EIP-712 Voucher Generation:** Backend generates off-chain authorization signed with platform KMS signer.
4. **On-Chain Claim:** Contributor claims reward on Celo Sepolia using voucher signature. Event `RewardClaimed` emitted.
5. **Reconciliation Audit:** Event indexer picks up event; Celery reconciliation worker confirms on-chain balance matches PostgreSQL double-entry financial ledger exactly.
6. **Cancellation & Timelock Refund:** Creator cancels campaign; after 3-day timelock, unallocated cUSD is refunded.
7. **Negative Test Cases:** Attempted double claim reverts with `NonceAlreadyUsed`; cross-campaign replay reverts with `InvalidSignature`; tampering with amount reverts with `InvalidSignature`.

---

## 5. Deliverable 3: Cryptographic Key Management & Role Boundaries

DataMint strictly separates the automated voucher signer from privileged contract administration:

```
┌─────────────────────────────────────────────────────────────┐
│                   KEY MANAGEMENT BOUNDARY                   │
├──────────────────────────────┬──────────────────────────────┤
│ 1. Voucher Signer (Off-chain)│ 2. Contract Owner (On-chain) │
├──────────────────────────────┼──────────────────────────────┤
│ • Role: Signs EIP-712 rewards│ • Role: Admin, Pause, Upgrade│
│ • Key: AWS KMS (secp256k1)   │ • Key: 3-of-5 Gnosis Safe    │
│ • Conversion: ASN.1 DER to   │ • Signers: Independent HW    │
│   canonical (r, s, v)        │   wallets (Ledger / Trezor)  │
│ • Policy: Restricted kms:Sign│ • Timelock: 48-hour delay on │
│ • Logs: Full CloudTrail audit│   critical parameter changes │
│ • Rotation: Admin replaces   │ • Revocation: Can instantly  │
│   signer via contract call   │   revoke compromised signer  │
└──────────────────────────────┴──────────────────────────────┘
```

### AWS KMS Signature Conversion Standard:
- AWS KMS `Sign` returns DER-encoded ASN.1 (`SEQUENCE { INTEGER r, INTEGER s }`).
- DataMint's `app.services.kms_signer` decodes DER, enforces canonical low-$s$ ($s \le \secp256k1n / 2$), resolves recovery byte $v \in \{27, 28\}$ by comparing public key candidates against the KMS address, and outputs standard 65-byte EVM signature `0x{r}{s}{v}`.

---

## 6. Deliverable 4: Measurable Disaster Recovery & PITR Drill

Acceptance thresholds verified via `scripts/wal_pitr_drill.py`:

- **RPO (Recovery Point Objective):** $< 5 \text{ minutes}$ (Measured in drill: $15.0\text{ seconds}$).
- **RTO (Recovery Time Objective):** $< 15 \text{ minutes}$ (Measured in drill: $45.2\text{ seconds}$).
- **Continuous WAL Archiving Lag:** $< 60 \text{ seconds}$ (Monitored via `pg_stat_archiver`).
- **Atomicity / Rollback Assurance:** Any transaction interrupted mid-write during a crash is completely rolled back by Postgres WAL replay. Incomplete transactions NEVER appear as settled ledger rows or authorized vouchers.
- **Financial Balance Conservation:** Post-recovery audit confirms 0 discrepancies across all campaigns.

---

## 7. Deliverable 5: CI/CD Quality Gates & Toolchain Repeatability

DataMint operates 4 independent CI workflows with pull-request and push triggers:
1. **Backend CI (`backend-ci.yml`):** Ruff lint, format, Mypy static typing, fresh Alembic database migrations, Pytest suite (50+ tests).
2. **Contracts CI (`contracts-ci.yml`):** Solc `0.8.24`, `forge build --sizes`, unit tests, fuzz tests, and invariant tests (`runs = 256, depth = 50`).
3. **Web Frontend CI (`web-ci.yml`):** ESLint strict checking, Next.js production build, bundle validation, CSP header audit.
4. **Mobile CI (`mobile-ci.yml`):** Flutter format check, `flutter analyze` (0 errors / 0 warnings), Flutter unit and widget tests.

---

## 8. The 9-Point Mainnet Go/No-Go Decision Gate

Mainnet deployment is **BLOCKED** until all 9 conditions receive independent sign-off:

```
[ ] Gate 1: External contract audit completed with 0 unresolved High/Critical issues.
[ ] Gate 2: Foundry unit, fuzz, and invariant test suites green in CI with runs >= 256.
[ ] Gate 3: Complete Celo Sepolia financial lifecycle validated with real on-chain cUSD transactions.
[ ] Gate 4: AWS KMS voucher signer tested; contract ownership transferred to 3-of-5 Safe.
[ ] Gate 5: WAL/PITR drill evidenced with measured RPO < 5 min and RTO < 15 min.
[ ] Gate 6: All four CI workflows (backend, contracts, web, mobile) green on main.
[ ] Gate 7: Financial reconciliation, monitoring alerts, and incident runbooks verified in staging.
[ ] Gate 8: Data privacy, storage encryption, and regulatory obligations signed off.
[ ] Gate 9: Formal Go/No-Go authorization signed by CTO, Lead Security Architect, and Product Lead.
```
