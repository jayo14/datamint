#!/usr/bin/env bash
set -eo pipefail

echo "==> [DataMint] Initializing backend container process..."

# Check if database host is reachable when DATABASE_URL is configured
if [ -n "${DATABASE_URL:-}" ]; then
    echo "==> [DataMint] Checking database connectivity..."
    python - <<'EOF'
import os
import sys
import time
from urllib.parse import urlparse

db_url = os.getenv("DATABASE_URL", "")
# Handle postgresql+asyncpg scheme
parsed = urlparse(db_url.replace("+asyncpg", ""))
host = parsed.hostname or "localhost"
port = parsed.port or 5432

import socket
timeout = 30
start = time.time()
connected = False

print(f"==> [DataMint] Waiting for database at {host}:{port} (timeout: {timeout}s)...")
while time.time() - start < timeout:
    try:
        with socket.create_connection((host, port), timeout=2):
            connected = True
            break
    except (socket.timeout, ConnectionRefusedError, OSError):
        time.sleep(1)

if not connected:
    print(f"ERROR: Could not establish TCP connection to database at {host}:{port} within {timeout}s.", file=sys.stderr)
    sys.exit(1)

print("==> [DataMint] Database port is open and responding.")
EOF
fi

# Run database migrations if RUN_MIGRATIONS is set
if [ "${RUN_MIGRATIONS:-false}" = "true" ] || [ "${RUN_MIGRATIONS:-0}" = "1" ]; then
    echo "==> [DataMint] RUN_MIGRATIONS is enabled. Running Alembic database migrations..."
    alembic upgrade head
    echo "==> [DataMint] Alembic database migrations successfully applied."
fi

echo "==> [DataMint] Starting application: $@"
exec "$@"
