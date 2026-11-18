# ADR 0003: Immutable Double-Entry Financial Ledger

## Status
Accepted

## Context
Decentralized escrow systems are vulnerable to race conditions, out-of-order blockchain events, and drift between off-chain database counts and on-chain ERC20 token balances. Relying on mutable balance columns without historical audit journals invites catastrophic financial discrepancies.

## Decision
We enforce an immutable double-entry style financial ledger in `ledger_entries`:
1. Every financial event (`DEPOSIT`, `RESERVATION`, `UNRESERVATION`, `CLAIM`, `REFUND`) appends an immutable row.
2. The core accounting invariant:
   $$\text{Funded} = \text{Available} + \text{Reserved} + \text{Claimed} + \text{Refunded}$$
   must evaluate to true on every state transition.
3. Check constraints prevent balances from dropping below zero.
4. All entries require an idempotent `reference_id` to guarantee replay safety.

## Consequences
- **Positive:** Complete mathematical proof of solvency; forensic auditability; clean reconciliation with on-chain smart contracts.
- **Negative:** Slightly higher storage requirements for ledger rows compared to simple column updates.
