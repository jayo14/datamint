# syntax=docker/dockerfile:1
# Multi-stage production Dockerfile for DataMint Backend API

# ------------------------------------------------------------------------------
# Stage 1: Build & Dependency Wheel Cache
# ------------------------------------------------------------------------------
FROM python:3.12-slim AS builder

WORKDIR /build

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    curl \
    && rm -rf /var/lib/apt/lists/*

COPY pyproject.toml README.md ./
RUN pip install --upgrade pip && \
    pip wheel --no-cache-dir --wheel-dir /build/wheels -e .

# ------------------------------------------------------------------------------
# Stage 2: Final Minimal Runtime Image
# ------------------------------------------------------------------------------
FROM python:3.12-slim AS runtime

WORKDIR /app

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PATH="/app/.venv/bin:$PATH"

RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq5 \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Create dedicated non-root application user
RUN groupadd -g 10001 datamint && \
    useradd -u 10001 -g datamint -m -s /bin/bash datamint

COPY --from=builder /build/wheels /tmp/wheels
COPY pyproject.toml README.md ./

RUN python -m venv /app/.venv && \
    /app/.venv/bin/pip install --upgrade pip && \
    /app/.venv/bin/pip install --no-cache-dir /tmp/wheels/* && \
    rm -rf /tmp/wheels

COPY . /app

RUN chown -R datamint:datamint /app

USER datamint

EXPOSE 8000

HEALTHCHECK --interval=15s --timeout=5s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:8000/api/v1/health/healthz || exit 1

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "4"]
