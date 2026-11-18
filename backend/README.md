# DataMint Backend

FastAPI modular monolith backend for the DataMint AI dataset marketplace on Celo.

## Features
- **FastAPI** with asynchronous request handlers and automatic OpenAPI documentation.
- **SQLAlchemy 2.0 (async)** with PostgreSQL and Alembic migrations.
- **EIP-4361 (SIWE)** decentralized authentication and JWT sessions.
- **Strict Financial Invariants:** Double-entry ledger for campaign escrow accounting.
- **Dual-Capability Identity:** Users seamlessly act as contributors, creators, or both.

## Getting Started

```bash
# Setup virtual environment and install dependencies
uv venv
source .venv/bin/activate
uv pip install -e ".[dev]"

# Run database migrations
alembic upgrade head

# Run local development server
uvicorn app.main:app --reload --port 8000
```
