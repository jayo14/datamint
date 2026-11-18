"""API v1 routers aggregator."""

from fastapi import APIRouter

from app.api.v1.auth import router as auth_router
from app.api.v1.campaigns import router as campaigns_router
from app.api.v1.health import router as health_router
from app.api.v1.marketplace import router as marketplace_router
from app.api.v1.media import router as media_router
from app.api.v1.payments import router as payments_router
from app.api.v1.submissions import router as submissions_router
from app.api.v1.users import router as users_router
from app.api.v1.wallets import router as wallets_router

api_v1_router = APIRouter()
api_v1_router.include_router(health_router)
api_v1_router.include_router(auth_router)
api_v1_router.include_router(users_router)
api_v1_router.include_router(wallets_router)
api_v1_router.include_router(campaigns_router)
api_v1_router.include_router(marketplace_router)
api_v1_router.include_router(submissions_router)
api_v1_router.include_router(media_router)
api_v1_router.include_router(payments_router)
