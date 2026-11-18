"""DataMint FastAPI Application Entry Point."""

import uuid
from contextlib import asynccontextmanager
from typing import AsyncGenerator

from fastapi import FastAPI, Request, Response
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse, RedirectResponse
from starlette.middleware.base import BaseHTTPMiddleware

from app.api.v1 import api_v1_router
from app.core.config import settings
from app.core.exceptions import DataMintException
from app.core.logging import setup_logging


class SecurityHeadersAndCorrelationMiddleware(BaseHTTPMiddleware):
    """Middleware enforcing correlation IDs and OWASP recommended security headers."""

    async def dispatch(self, request: Request, call_next) -> Response:
        request_id = request.headers.get("X-Request-ID") or str(uuid.uuid4())
        request.state.request_id = request_id

        response = await call_next(request)

        response.headers["X-Request-ID"] = request_id
        response.headers["X-Content-Type-Options"] = "nosniff"
        response.headers["X-Frame-Options"] = "DENY"
        response.headers["Content-Security-Policy"] = (
            "default-src 'self'; object-src 'none'; base-uri 'self'; frame-ancestors 'none'; "
            "form-action 'self'; img-src 'self' data: https:; style-src 'self' 'unsafe-inline'"
        )
        response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
        if settings.ENVIRONMENT.lower() in ("production", "staging"):
            response.headers["Strict-Transport-Security"] = (
                "max-age=31536000; includeSubDomains; preload"
            )
        return response


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncGenerator[None, None]:
    """Application startup and shutdown hooks."""
    setup_logging()
    yield


app = FastAPI(
    title=settings.PROJECT_NAME,
    version="1.0.0",
    description=(
        "DataMint is a decentralized AI dataset marketplace powered by human contributors and Celo payments.\n\n"
        "### Core Features:\n"
        "* **Decentralized SIWE (EIP-4361)** wallet authentication\n"
        "* **Dual-capability identity** (contributor + creator in one account)\n"
        "* **Double-entry financial ledger** enforcing the invariant Funded = Claimed + Reserved + Available + Refunded\n"
        "* **Non-custodial EIP-712 pull-payment vouchers** for instant cUSD claim on Celo\n"
    ),
    openapi_url="/openapi.json",
    docs_url="/docs",
    redoc_url="/redoc",
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

# Security Headers & Correlation ID Middleware
app.add_middleware(SecurityHeadersAndCorrelationMiddleware)


@app.exception_handler(DataMintException)
async def datamint_exception_handler(request: Request, exc: DataMintException) -> JSONResponse:
    """Standardized error responses for all domain exceptions."""
    return JSONResponse(
        status_code=exc.status_code,
        content=exc.detail if isinstance(exc.detail, dict) else {"message": str(exc.detail)},
    )


# Include domain routers under /api/v1
app.include_router(api_v1_router, prefix=settings.API_V1_STR)


@app.get("/api/v1/docs", include_in_schema=False)
async def legacy_docs_redirect():
    """Redirect legacy /api/v1/docs to root /docs route."""
    return RedirectResponse(url="/docs")


@app.get("/", tags=["Root"])
async def root() -> dict:
    return {
        "name": settings.PROJECT_NAME,
        "version": "1.0.0",
        "docs": "/docs",
        "redoc": "/redoc",
        "openapi": "/openapi.json",
        "status": "operational",
    }
