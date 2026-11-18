# ADR 0004: Offline-First Operation and Fault Tolerance

## Status
Accepted

## Context
A critical design requirement is that DataMint must remain operationally functional even if external third-party dependencies (AI providers or Celo RPC nodes) suffer outages or network partitions.

## Decision
1. **Asynchronous Queuing:** All AI validation requests and blockchain event synchronizations are pushed to background queues (Celery + Redis) with retry policies and exponential backoff.
2. **Graceful Degradation:** When an AI validator is unresponsive, submissions remain securely stored in `QUEUED_FOR_VALIDATION` state without failing the contributor's experience.
3. **Optimistic Off-Chain Reservations:** When a submission is approved, funds are reserved in the local ledger immediately. Payout vouchers are generated and stored, ready for on-chain withdrawal whenever the blockchain is reachable.

## Consequences
- **Positive:** Zero data loss during third-party downtime; seamless user experience regardless of external network latency.
- **Negative:** Requires background worker monitoring and dead-letter queue management.
