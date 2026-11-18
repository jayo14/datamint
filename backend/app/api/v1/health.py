"""Health and readiness probes."""

import redis.asyncio as aioredis
from fastapi import APIRouter, Depends, Response, status
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.database import get_db

router = APIRouter(prefix="/health", tags=["Health"])


@router.get("/healthz", status_code=status.HTTP_200_OK)
async def liveness_probe() -> dict:
    """Liveness probe verifying that the service process is up."""
    return {"status": "ok", "service": "datamint-api"}


@router.get("/readyz", status_code=status.HTTP_200_OK)
async def readiness_probe(response: Response, db: AsyncSession = Depends(get_db)) -> dict:
    """Readiness probe verifying database and cache/broker connectivity."""
    checks = {
        "database": "unreachable",
        "redis": "unreachable",
    }
    is_ready = True

    try:
        await db.execute(text("SELECT 1"))
        checks["database"] = "connected"
    except Exception as e:
        checks["database"] = f"error: {str(e)}"
        is_ready = False

    # Check redis connectivity
    if settings.REDIS_URL:
        try:
            r = aioredis.from_url(settings.REDIS_URL, socket_connect_timeout=0.5)
            await r.ping()
            await r.aclose()
            checks["redis"] = "connected"
        except Exception as e:
            checks["redis"] = f"unreachable: {str(e)}"
            if settings.ENVIRONMENT in ("production", "staging"):
                is_ready = False
    else:
        checks["redis"] = "disabled"

    if not is_ready:
        response.status_code = status.HTTP_503_SERVICE_UNAVAILABLE
        return {"status": "degraded", **checks}

    return {"status": "ready", **checks}
