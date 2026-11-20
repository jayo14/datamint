# DataMint Backend Docker & Production Deployment Guide

This guide details how to build, configure, test, and deploy the containerized DataMint backend API and Celery background workers.

---

## 1. Architecture Overview

The backend production topology consists of four containerized services running on an isolated network bridge:

1. **`datamint-backend`**: Multi-worker FastAPI ASGI application served via Gunicorn and Uvicorn workers.
2. **`datamint-worker`**: Celery asynchronous task executor handling background AI validation and blockchain settlement.
3. **`datamint-beat`**: Celery Beat scheduler executing periodic sync tasks (blockchain event indexer, expired authorization cleanup, ledger balance reconciliation).
4. **`postgres` & `redis`**: Persistent relational storage (PostgreSQL 16) and fast caching/task brokering (Redis 7).

---

## 2. Container Images

### Building the Backend API Image
```bash
docker build \
  -t datamint-backend:latest \
  -f backend/Dockerfile \
  backend/
```

### Building the Celery Worker Image
```bash
docker build \
  -t datamint-worker:latest \
  -f backend/Dockerfile.worker \
  backend/
```

### Multi-Architecture Builds (amd64 / arm64)
```bash
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t ghcr.io/datamint/backend:v1.0.0 \
  -f backend/Dockerfile \
  --push \
  backend/
```

---

## 3. Configuration & Environment Variables

Copy `backend/.env.example` to `backend/.env` and configure production secrets:

| Variable | Description | Example / Default |
| :--- | :--- | :--- |
| `ENVIRONMENT` | Runtime mode (`production`, `staging`, `development`) | `production` |
| `DATABASE_URL` | PostgreSQL asyncpg connection URI | `postgresql+asyncpg://admin:pass@postgres:5432/datamint_prod` |
| `REDIS_URL` | Redis broker and cache connection URI | `redis://:pass@redis:6379/0` |
| `JWT_SECRET_KEY` | Cryptographic secret (minimum 32 chars) | Generated via `openssl rand -hex 32` |
| `CELO_RPC_URL` | Celo blockchain RPC node endpoint | `https://forno.celo.org` |
| `CELO_CHAIN_ID` | Celo network chain identifier | `42220` (Mainnet) or `44787` (Alfajores) |
| `ESCROW_CONTRACT_ADDRESS` | Deployed DatasetEscrow contract | `0x...` |
| `PLATFORM_SIGNER_PRIVATE_KEY`| Private key for EIP-712 payout vouchers | `0x...` |
| `RUN_MIGRATIONS` | Auto-run Alembic migrations on startup | `true` |
| `WORKERS` | Number of Gunicorn worker processes | `4` |

---

## 4. Deploying with Docker Compose

### Production Stack Deployment
```bash
# 1. Provide production environment file
cp backend/.env.example .env.prod
# Edit secrets in .env.prod

# 2. Launch production stack with health checks
docker compose -f docker-compose.prod.yml --env-file .env.prod up -d

# 3. Verify health status of all containers
docker compose -f docker-compose.prod.yml ps

# 4. View live logs
docker compose -f docker-compose.prod.yml logs -f backend
```

---

## 5. Automated Database Migrations

The container entrypoint script (`backend/entrypoint.sh`) handles migrations automatically when `RUN_MIGRATIONS=true`:
1. Verifies TCP network connectivity to PostgreSQL.
2. Runs `alembic upgrade head`.
3. Passes execution to Gunicorn/Celery as PID 1 for clean signal handling.

To manually run migrations against a running container:
```bash
docker exec -it datamint-backend-prod alembic upgrade head
```

---

## 6. Probes & Monitoring

- **Liveness probe:** `GET /api/v1/health/healthz` (Returns HTTP 200 when API process is alive).
- **Readiness probe:** `GET /api/v1/health/readyz` (Verifies live connectivity to PostgreSQL and Redis; returns HTTP 503 if dependencies fail).
