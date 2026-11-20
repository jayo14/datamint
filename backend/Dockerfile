# syntax=docker/dockerfile:1
# ==============================================================================
# Multi-stage Production Dockerfile for DataMint FastAPI Monolith Backend
# Target Architecture: linux/amd64, linux/arm64
# Base: Debian Bookworm Slim with Python 3.12
# ==============================================================================

# ------------------------------------------------------------------------------
# Stage 1: Build & Dependency Installation
# ------------------------------------------------------------------------------
FROM python:3.12-slim AS builder

WORKDIR /build

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Install system build dependencies required for C-extensions (asyncpg, cryptography, etc.)
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Create isolated production virtual environment
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Copy package definition and application code to install wheel and dependencies
COPY pyproject.toml README.md ./
COPY app/ ./app/

# Install build dependencies and production packages
RUN pip install --upgrade pip setuptools wheel && \
    pip install --no-cache-dir .

# ------------------------------------------------------------------------------
# Stage 2: Minimal Production Runtime
# ------------------------------------------------------------------------------
FROM python:3.12-slim AS runtime

WORKDIR /app

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PATH="/opt/venv/bin:$PATH" \
    PORT=8000 \
    HOST=0.0.0.0 \
    WORKERS=4 \
    ENVIRONMENT=production

# Install minimal runtime libraries (libpq5 for PostgreSQL, curl for container health probes)
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq5 \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Create dedicated non-root application user and group
RUN groupadd -g 10001 datamint && \
    useradd -u 10001 -g datamint -m -s /bin/bash datamint

# Copy compiled virtual environment from builder stage
COPY --from=builder /opt/venv /opt/venv

# Copy application codebase and configuration
COPY --chown=datamint:datamint . /app

# Ensure entrypoint script is executable
RUN chmod +x /app/entrypoint.sh

# Run as non-privileged application user
USER datamint

EXPOSE 8000

# Container liveness healthcheck
HEALTHCHECK --interval=15s --timeout=5s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:8000/api/v1/health/healthz || exit 1

ENTRYPOINT ["/app/entrypoint.sh"]

CMD ["sh", "-c", "uvicorn app.main:app --host ${HOST} --port ${PORT} --workers ${WORKERS} --proxy-headers --forwarded-allow-ips '*'"]
