"""Media access and presigned download URL endpoints."""

import uuid

from fastapi import APIRouter, Depends, Request, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user
from app.core.database import get_db
from app.core.rate_limit import media_rate_limiter
from app.models.identity import User
from app.schemas.submission import DownloadUrlResponse
from app.services.submission_service import SubmissionService

router = APIRouter(prefix="/media", tags=["Media"])


@router.get(
    "/submissions/{submission_id}/assets/{asset_id}/download-url",
    response_model=DownloadUrlResponse,
    status_code=status.HTTP_200_OK,
)
async def get_media_download_url(
    submission_id: uuid.UUID,
    asset_id: uuid.UUID,
    request: Request,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> DownloadUrlResponse:
    """
    Generate short-lived presigned download URL for a submission media asset.
    Access is restricted strictly to the submitting contributor or the dataset campaign creator.
    """
    await media_rate_limiter.check(request, key_prefix="media:download")
    service = SubmissionService(db)
    download_url = await service.get_media_download_url(
        submission_id=submission_id,
        asset_id=asset_id,
        requesting_user_id=current_user.id,
    )
    return DownloadUrlResponse(download_url=download_url, expires_in_seconds=1800)
