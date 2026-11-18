# ADR 0001: Adopt FastAPI Modular Monolith Architecture

## Status
Accepted

## Context
DataMint connects multiple client applications (Next.js web app, Flutter mobile app) with AI evaluation services and the Celo blockchain. A microservices architecture at this stage would introduce distributed transactions, network latency, deployment complexity, and synchronization friction between campaign, submission, and escrow state.

## Decision
We adopt a **modular monolith** using Python 3.12+ and FastAPI.
1. All domain models and services reside within a single codebase in `backend/app/`.
2. Clear module boundaries are enforced at the package level (`identity`, `campaigns`, `submissions`, `validation`, `escrow`).
3. Communication between domains uses typed Python service calls within the same process.
4. Asynchronous background jobs (e.g., AI inference, blockchain indexing) are handled by Celery workers over a shared Redis queue.

## Consequences
- **Positive:** Single atomic transactions across PostgreSQL tables; unified deployment; rapid engineering cadence; shared schema validation via Pydantic v2.
- **Negative:** Requires rigorous module boundary hygiene to prevent circular dependencies.
