"""Health and readiness probes."""

from fastapi import APIRouter, Depends, status
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.database import get_db

router = APIRouter(prefix="/health", tags=["Health"])


@router.get("/healthz", status_code=status.HTTP_200_OK)
async def liveness_probe() -> dict:
    """Liveness probe verifying that the service process is up."""
    return {"status": "ok", "service": "datamint-api"}


@router.get("/readyz", status_code=status.HTTP_200_OK)
async def readiness_probe(db: AsyncSession = Depends(get_db)) -> dict:
    """Readiness probe verifying database connectivity."""
    try:
        await db.execute(text("SELECT 1"))
        return {"status": "ready", "database": "connected"}
    except Exception as e:
        return {"status": "degraded", "database": "unreachable", "error": str(e)}
