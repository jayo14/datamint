"""In-app notifications API endpoints."""

import uuid
from typing import List

from fastapi import APIRouter, Depends, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user
from app.core.database import get_db
from app.core.exceptions import EntityNotFoundException
from app.models.identity import User
from app.models.notification import Notification
from app.schemas.notification import NotificationResponse

router = APIRouter(prefix="/notifications", tags=["Notifications"])


@router.get("", response_model=List[NotificationResponse], status_code=status.HTTP_200_OK)
async def list_user_notifications(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> List[NotificationResponse]:
    """List recent notifications for authenticated user."""
    query = (
        select(Notification)
        .where(Notification.user_id == current_user.id)
        .order_by(Notification.created_at.desc())
        .limit(50)
    )
    notifications = (await db.execute(query)).scalars().all()
    return [NotificationResponse.model_validate(n) for n in notifications]


@router.put(
    "/{notification_id}/read", response_model=NotificationResponse, status_code=status.HTTP_200_OK
)
async def mark_notification_read(
    notification_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> NotificationResponse:
    """Mark a notification as read."""
    query = select(Notification).where(
        Notification.id == notification_id,
        Notification.user_id == current_user.id,
    )
    notification = (await db.execute(query)).scalar_one_or_none()
    if not notification:
        raise EntityNotFoundException("Notification", notification_id)

    notification.is_read = True
    await db.commit()
    return NotificationResponse.model_validate(notification)
