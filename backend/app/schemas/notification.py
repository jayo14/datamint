"""Pydantic schemas for user notifications."""

import uuid
from datetime import datetime
from typing import Any, Dict, Optional

from pydantic import BaseModel, ConfigDict


class NotificationResponse(BaseModel):
    """Notification item for user status updates and vouchers."""

    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    user_id: uuid.UUID
    event_type: str
    title: str
    message: str
    data_json: Optional[Dict[str, Any]] = None
    is_read: bool
    created_at: datetime
