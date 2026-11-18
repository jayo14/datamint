"""API v1 routers aggregator."""

from fastapi import APIRouter

from app.api.v1.appeals import router as appeals_router
from app.api.v1.auth import router as auth_router
from app.api.v1.campaigns import router as campaigns_router
from app.api.v1.health import router as health_router
from app.api.v1.marketplace import router as marketplace_router
from app.api.v1.media import router as media_router
from app.api.v1.notifications import router as notifications_router
from app.api.v1.payments import router as payments_router
from app.api.v1.payouts import router as payouts_router
from app.api.v1.reconciliation import router as reconciliation_router
from app.api.v1.reviews import router as reviews_router
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
api_v1_router.include_router(reviews_router)
api_v1_router.include_router(appeals_router)
api_v1_router.include_router(payouts_router)
api_v1_router.include_router(reconciliation_router)
api_v1_router.include_router(notifications_router)
