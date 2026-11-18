# DataMint Financial Ledger & Accounting Invariants

## 1. The Core Accounting Invariant

The integrity of DataMint depends entirely on deterministic, immutable bookkeeping that mirrors escrow contracts on Celo.

For every campaign funded via `DataMintEscrow`, the following invariant **MUST HOLD TRUE AT ALL TIMES**:

$$\text{Total Funded} = \text{Total Available} + \text{Total Reserved} + \text{Total Claimed} + \text{Total Refunded}$$

Where:
- **Total Funded ($F$):** Total cUSD deposited on-chain by the creator into escrow.
- **Total Available ($A$):** Remaining funds unallocated, ready to reward new submissions.
- **Total Reserved ($R$):** Funds locked for approved submissions awaiting on-chain claim by contributors.
- **Total Claimed ($C$):** Funds successfully withdrawn on-chain by contributors.
- **Total Refunded ($X$):** Unspent funds returned to the campaign creator upon campaign cancellation or expiration.

### Non-Negativity Invariant:
$$\forall c \in \text{EscrowCampaigns}: \quad F_c \ge 0, \quad A_c \ge 0, \quad R_c \ge 0, \quad C_c \ge 0, \quad X_c \ge 0$$

Under no circumstances may any bucket drop below zero.

---

## 2. Double-Entry Ledger State Transitions

Every financial movement in DataMint requires an immutable row in `ledger_entries`. The table below outlines how state buckets transform across events:

| Event Type | Trigger | Ledger Entry Type | $\Delta \text{Funded}$ | $\Delta \text{Available}$ | $\Delta \text{Reserved}$ | $\Delta \text{Claimed}$ | $\Delta \text{Refunded}$ |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Deposit Confirmed** | Creator funds campaign on-chain | `DEPOSIT` | $+V$ | $+V$ | $0$ | $0$ | $0$ |
| **Submission Approved** | AI/Human marks submission valid | `RESERVATION` | $0$ | $-P$ | $+P$ | $0$ | $0$ |
| **Submission Revoked/Failed** | Appeal rejection or dispute | `UNRESERVATION` | $0$ | $+P$ | $-P$ | $0$ | $0$ |
| **Payout Claimed** | Contributor executes claim on-chain | `CLAIM` | $0$ | $0$ | $-P$ | $+P$ | $0$ |
| **Campaign Refund** | Creator cancels expired campaign | `REFUND` | $0$ | $-Rem$ | $0$ | $0$ | $+Rem$ |

*$V$ = Total deposit amount, $P$ = Reward per submission, $Rem$ = Remaining available balance.*

---

## 3. Idempotency & Reconciliation

To ensure offline resilience and network fault tolerance:

### 3.1 Idempotency Keys
Every financial operation requires a unique `reference_id`:
- Deposits use the blockchain transaction hash: `celo:tx:<tx_hash>:<log_index>`.
- Reservations use the submission UUID: `sub:reserve:<submission_id>`.
- Claims use the withdrawal transaction hash: `celo:claim:<tx_hash>:<voucher_hash>`.
- Refunds use the refund transaction hash: `celo:refund:<tx_hash>`.

If an operation with an existing `reference_id` is replayed, the ledger returns the existing transaction without executing duplicate state mutations.

### 3.2 Offline Disconnection Resilience
If the Celo blockchain node or RPC endpoint goes offline:
1. Submissions can still be received, stored, and evaluated by AI validation workers.
2. Valid submissions still reserve funds off-chain in PostgreSQL (`Total Reserved`).
3. Vouchers (EIP-712 cryptographic proofs) are signed and stored locally in `payout_authorizations`.
4. As soon as Celo RPC connectivity is restored, contributors submit their pending claims.
5. Invariant reconciliation jobs verify that the on-chain contract balance equals $(A + R)$.
