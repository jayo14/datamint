"""Production Gunicorn ASGI Configuration for DataMint FastAPI Monolith."""

import multiprocessing
import os

# Server socket
host = os.getenv("HOST", "0.0.0.0")
port = os.getenv("PORT", "8000")
bind = f"{host}:{port}"

# Worker processes
# Calculate workers based on CPU cores or WORKERS / WEB_CONCURRENCY env var
default_workers = max(multiprocessing.cpu_count() * 2 + 1, 2)
workers = int(os.getenv("WORKERS", os.getenv("WEB_CONCURRENCY", str(default_workers))))

# Worker type: uvicorn async worker
worker_class = "uvicorn.workers.UvicornWorker"
worker_connections = 1000

# Lifecycle & Timeouts
timeout = int(os.getenv("GUNICORN_TIMEOUT", "60"))
keepalive = int(os.getenv("GUNICORN_KEEPALIVE", "5"))
graceful_timeout = int(os.getenv("GUNICORN_GRACEFUL_TIMEOUT", "30"))

# Worker recycling to mitigate memory fragmentation in long-running processes
max_requests = int(os.getenv("MAX_REQUESTS", "10000"))
max_requests_jitter = int(os.getenv("MAX_REQUESTS_JITTER", "1000"))

# Logging to standard out/err for Docker log ingestion
accesslog = "-"
errorlog = "-"
loglevel = os.getenv("LOG_LEVEL", "info")
access_log_format = '%(h)s %(l)s %(u)s %(t)s "%(r)s" %(s)s %(b)s "%(f)s" "%(a)s" %(L)ss'

# Process naming
proc_name = "datamint-api"
