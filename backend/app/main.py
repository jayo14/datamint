"""DataMint FastAPI Application Entry Point."""

from contextlib import asynccontextmanager
from typing import AsyncGenerator
from fastapi import FastAPI, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from app.api.v1 import api_v1_router
from app.core.config import settings
from app.core.exceptions import DataMintException
from app.core.logging import setup_logging


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncGenerator[None, None]:
    """Application startup and shutdown hooks."""
    setup_logging()
    yield


app = FastAPI(
    title=settings.PROJECT_NAME,
    version="1.0.0",
    description="""
    DataMint is a decentralized AI dataset marketplace powered by human contributors and Celo payments.
    
    ### Core Features:
    * **Decentralized SIWE (EIP-4361)** wallet authentication
    * **Dual-capability identity** (contributor + creator in one account)
    * **Double-entry financial ledger** enforcing the invariant `Funded = Claimed + Reserved + Available + Refunded`
    * **Non-custodial EIP-712 pull-payment vouchers** for instant cUSD claim on Celo
    """,
    openapi_url=f"{settings.API_V1_STR}/openapi.json",
    docs_url=f"{settings.API_V1_STR}/docs",
    redoc_url=f"{settings.API_V1_STR}/redoc",
    lifespan=lifespan,
)

# CORS Middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.exception_handler(DataMintException)
async def datamint_exception_handler(request: Request, exc: DataMintException) -> JSONResponse:
    """Standardized error responses for all domain exceptions."""
    return JSONResponse(
        status_code=exc.status_code,
        content=exc.detail if isinstance(exc.detail, dict) else {"message": str(exc.detail)},
    )


# Include domain routers under /api/v1
app.include_router(api_v1_router, prefix=settings.API_V1_STR)


@app.get("/", tags=["Root"])
async def root() -> dict:
    return {
        "name": settings.PROJECT_NAME,
        "version": "1.0.0",
        "docs": f"{settings.API_V1_STR}/docs",
        "status": "operational",
    }
