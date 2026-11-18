"""Phase 3 tests for Secure Media Handling, MIME Validation, and Private Download Access."""

from decimal import Decimal

import pytest

from app.models.enums import DataType
from app.services.campaign_service import CampaignService


@pytest.mark.asyncio
async def test_media_upload_validation_and_access_control(async_client, db_session):
    """Verify MIME/size validation, upload workflow, and strict download access control."""
    campaign_service = CampaignService(db_session)

    # 1. Setup creator and voice campaign
    reg_creator = await async_client.post(
        "/api/v1/auth/register",
        json={"email": "media_creator@datamint.ai", "password": "PasswordMedia123!"},
    )
    creator_id = reg_creator.json()["user"]["id"]
    creator_headers = {"Authorization": f"Bearer {reg_creator.json()['access_token']}"}

    campaign = await campaign_service.create_campaign(
        creator_id=creator_id,
        data={
            "title": "Private Voice Dataset",
            "description": "Voice audio recordings requiring private storage",
            "data_type": DataType.VOICE,
            "target_submissions": 10,
            "reward_per_submission": Decimal("3.00"),
        },
    )
    campaign.escrow.total_funded = Decimal("30.00")
    campaign.escrow.total_available = Decimal("30.00")
    await campaign_service.activate_campaign(campaign.id, "0x" + "b" * 64)
    await db_session.commit()

    # 2. Setup contributor
    reg_contrib = await async_client.post(
        "/api/v1/auth/register",
        json={"email": "media_contrib@datamint.ai", "password": "PasswordContrib123!"},
    )
    contrib_headers = {"Authorization": f"Bearer {reg_contrib.json()['access_token']}"}

    # Contributor creates draft
    draft_res = await async_client.post(
        "/api/v1/submissions/drafts",
        json={"campaign_id": str(campaign.id)},
        headers=contrib_headers,
    )
    assert draft_res.status_code == 201
    sub_id = draft_res.json()["id"]

    # 3. Test invalid MIME type rejection
    bad_mime_res = await async_client.post(
        f"/api/v1/submissions/drafts/{sub_id}/upload-url",
        json={
            "filename": "malicious.exe",
            "mime_type": "application/x-executable",
            "byte_size": 1024,
            "asset_type": "AUDIO",
        },
        headers=contrib_headers,
    )
    assert bad_mime_res.status_code == 400
    assert "not permitted" in bad_mime_res.json()["detail"]

    # 4. Test oversized file rejection (>50MB for VOICE)
    oversized_res = await async_client.post(
        f"/api/v1/submissions/drafts/{sub_id}/upload-url",
        json={
            "filename": "giant_audio.wav",
            "mime_type": "audio/wav",
            "byte_size": 60 * 1024 * 1024,  # 60 MB
            "asset_type": "AUDIO",
        },
        headers=contrib_headers,
    )
    assert oversized_res.status_code == 400
    assert "exceeds maximum" in oversized_res.json()["detail"]

    # 5. Test valid upload URL issuance
    valid_upload_res = await async_client.post(
        f"/api/v1/submissions/drafts/{sub_id}/upload-url",
        json={
            "filename": "clean_speech.wav",
            "mime_type": "audio/wav",
            "byte_size": 5 * 1024 * 1024,  # 5 MB
            "asset_type": "AUDIO",
        },
        headers=contrib_headers,
    )
    assert valid_upload_res.status_code == 200
    upload_data = valid_upload_res.json()
    assert "upload_url" in upload_data
    assert "content-type=audio/wav" in upload_data["upload_url"]

    # Retrieve submission to get the generated asset id
    sub_detail_res = await async_client.get(
        f"/api/v1/submissions/{sub_id}",
        headers=contrib_headers,
    )
    assert sub_detail_res.status_code == 200
    asset_id = sub_detail_res.json()["assets"][0]["id"]

    # 6. Confirm upload
    confirm_res = await async_client.post(
        f"/api/v1/submissions/drafts/{sub_id}/confirm-upload",
        json={"asset_id": asset_id},
        headers=contrib_headers,
    )
    assert confirm_res.status_code == 200
    assert confirm_res.json()["is_uploaded"] is True

    # 7. Access Control on Download URL:
    # A) Submitting contributor -> ALLOWED
    dl_contrib = await async_client.get(
        f"/api/v1/media/submissions/{sub_id}/assets/{asset_id}/download-url",
        headers=contrib_headers,
    )
    assert dl_contrib.status_code == 200
    assert "download_url" in dl_contrib.json()

    # B) Dataset campaign creator -> ALLOWED
    dl_creator = await async_client.get(
        f"/api/v1/media/submissions/{sub_id}/assets/{asset_id}/download-url",
        headers=creator_headers,
    )
    assert dl_creator.status_code == 200
    assert "download_url" in dl_creator.json()

    # C) Unrelated third party user -> FORBIDDEN
    reg_other = await async_client.post(
        "/api/v1/auth/register",
        json={"email": "intruder@datamint.ai", "password": "PasswordIntruder123!"},
    )
    other_headers = {"Authorization": f"Bearer {reg_other.json()['access_token']}"}

    dl_other = await async_client.get(
        f"/api/v1/media/submissions/{sub_id}/assets/{asset_id}/download-url",
        headers=other_headers,
    )
    assert dl_other.status_code == 400
    assert "You do not have permission" in dl_other.json()["detail"]
