# DataMint v1 REST API Contracts

All endpoints are served under `/api/v1` and use standard JSON request and response bodies.

---

## 1. Authentication & Session Management (`/api/v1/auth`)

### 1.1 `POST /api/v1/auth/register`
Register a new user with email and password. Provisions dual capabilities (`CONTRIBUTOR` + `CREATOR`).
- **Request Body:**
  ```json
  {
    "email": "contributor@datamint.ai",
    "password": "StrongPassword123!",
    "display_name": "Data Pioneer"
  }
  ```
- **Response `201 Created`:**
  ```json
  {
    "access_token": "eyJhbGciOi...",
    "refresh_token": "eyJhbGciOi...",
    "token_type": "bearer",
    "expires_in": 900,
    "user": {
      "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
      "email": "contributor@datamint.ai",
      "primary_wallet": null,
      "capabilities": ["CONTRIBUTOR", "CREATOR"]
    }
  }
  ```

### 1.2 `POST /api/v1/auth/login`
Authenticate an existing user with email and password.
- **Request Body:**
  ```json
  {
    "email": "contributor@datamint.ai",
    "password": "StrongPassword123!"
  }
  ```
- **Response `200 OK`:** Same schema as register response.

### 1.3 `POST /api/v1/auth/nonce`
Generate an EIP-4361 compliant nonce challenge for wallet signature.
- **Request Body:**
  ```json
  {
    "address": "0x742d35Cc6634C0532925a3b844Bc454e4438f44e",
    "chain_id": 42220,
    "action": "login"
  }
  ```
- **Response `200 OK`:**
  ```json
  {
    "nonce": "d8f49a37e1b5c82a",
    "message": "datamint.ai wants you to sign in with your Celo account:\n0x742d35Cc6634C0532925a3b844Bc454e4438f44e\n\nAction: login\nURI: https://datamint.ai\nVersion: 1\nChain ID: 42220\nNonce: d8f49a37e1b5c82a\nIssued At: 2026-11-18T12:00:00Z",
    "action": "login",
    "expires_at": "2026-11-18T12:05:00Z"
  }
  ```

### 1.4 `POST /api/v1/auth/verify`
Verify signed EIP-4361 message and establish user session.
- **Request Body:**
  ```json
  {
    "message": "datamint.ai wants you to sign in...",
    "signature": "0x304502210089..."
  }
  ```
- **Response `200 OK`:** AuthTokenResponse.

### 1.5 `POST /api/v1/auth/refresh`
Rotate refresh token and issue a fresh access token.
- **Request Body:**
  ```json
  {
    "refresh_token": "eyJhbGciOi..."
  }
  ```
- **Response `200 OK`:** AuthTokenResponse.

### 1.6 `POST /api/v1/auth/logout`
Revoke active session(s). Requires Bearer token header.
- **Request Body:**
  ```json
  {
    "refresh_token": "eyJhbGciOi..."
  }
  ```
- **Response `200 OK`:** `{"status": "logged_out", "detail": "Session successfully revoked"}`

---

## 2. User & Profile Management (`/api/v1/users`)

### 2.1 `GET /api/v1/users/me`
Fetch profile details, capabilities, and verified wallets for authenticated user.
- **Headers:** `Authorization: Bearer <access_token>`
- **Response `200 OK`:**
  ```json
  {
    "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
    "email": "user@datamint.ai",
    "is_active": true,
    "is_verified": true,
    "created_at": "2026-11-18T10:00:00Z",
    "updated_at": "2026-11-18T10:00:00Z",
    "profile": {
      "display_name": "Data Pioneer",
      "avatar_url": "https://datamint.ai/avatars/user.png",
      "bio": "Specialist in multilingual speech datasets.",
      "metadata_json": {}
    },
    "capabilities": ["CONTRIBUTOR", "CREATOR"],
    "wallets": [
      {
        "id": "e5b8...-4562",
        "address": "0x742d35cc6634c0532925a3b844bc454e4438f44e",
        "chain_id": 42220,
        "is_primary": true,
        "verified_at": "2026-11-18T10:05:00Z"
      }
    ]
  }
  ```

### 2.2 `PUT /api/v1/users/me/profile`
Update user profile metadata.
- **Request Body:**
  ```json
  {
    "display_name": "Senior Annotator",
    "bio": "Voice and conversational dataset specialist.",
    "avatar_url": "https://datamint.ai/avatars/new.png"
  }
  ```
- **Response `200 OK`:** Updated profile object.

---

## 3. Cryptographic Wallet Management (`/api/v1/wallets`)

### 3.1 `GET /api/v1/wallets/`
List verified wallets linked to authenticated user.

### 3.2 `POST /api/v1/wallets/challenge`
Request an EIP-4361 nonce bound specifically to `action="link_wallet"` for the authenticated user.

### 3.3 `POST /api/v1/wallets/link`
Verify cryptographic signature of the link challenge and bind wallet to user account. Prevents reassigning wallets owned by other users.

### 3.4 `DELETE /api/v1/wallets/{address}`
Unlink wallet. Blocked if the wallet is the user's sole authentication method and no password exists.

### 3.5 `PUT /api/v1/wallets/{address}/primary`
Designate a linked wallet as the primary address for payout authorizations.

---

## 4. Campaigns Lifecycle (`/api/v1/campaigns`)

### 4.1 `POST /api/v1/campaigns/`
Create a dataset campaign in `DRAFT` state. Requires `CREATOR` capability.
- **Request Body:**
  ```json
  {
    "title": "East African Accents Audio Dataset",
    "description": "High-fidelity conversational speech samples across Kenyan regions",
    "data_type": "VOICE",
    "target_submissions": 500,
    "reward_per_submission": "1.50",
    "reward_currency": "cUSD",
    "category": "Speech Recognition",
    "tags": ["audio", "voice", "swahili", "english"],
    "instructions": "Record 20-30 seconds of conversational speech in a quiet room.",
    "eligibility_criteria": {
      "min_age": 18,
      "regions": ["KE"]
    }
  }
  ```

### 4.2 `PUT /api/v1/campaigns/{campaign_id}`
Update draft campaign fields. Modifying campaign terms is strictly blocked once submitted for funding or active (`CAMPAIGN_IMMUTABLE`).

### 4.3 `POST /api/v1/campaigns/{campaign_id}/submit-funding`
Transition draft campaign to `PENDING_FUNDING` and return computed parameters for `DatasetEscrow.createCampaign(...)`.
- **Response `200 OK`:**
  ```json
  {
    "campaign_id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
    "onchain_campaign_id": "0x4b7c89...",
    "reward_per_submission_wei": "1500000000000000000",
    "target_submissions": 500,
    "required_budget_wei": "750000000000000000000",
    "required_budget_formatted": "750.00 cUSD",
    "reward_currency": "cUSD",
    "contract_address": "0x...",
    "metadata_hash": "0x..."
  }
  ```

### 4.4 `GET /api/v1/campaigns/my-campaigns`
List campaigns created by the authenticated creator with pagination.

### 4.5 `GET /api/v1/campaigns/{campaign_id}`
Fetch full campaign details, requirements, and escrow balance.

---

## 5. Marketplace Task Discovery (`/api/v1/marketplace`)

### 5.1 `GET /api/v1/marketplace/tasks`
Public marketplace discovery of `ACTIVE` campaigns accepting submissions.
- **Query Parameters:**
  - `search` (string): Keyword match in `title` or `description`
  - `data_type` (string): `TEXT`, `VOICE`, `IMAGE`
  - `category` (string): Category name
  - `min_reward` (decimal): Minimum cUSD reward
  - `max_reward` (decimal): Maximum cUSD reward
  - `sort_by` (string): `newest`, `reward_high`, `reward_low`, `deadline`
  - `page` (int, default 1)
  - `page_size` (int, default 20)

---

## 6. Submissions & Media Orchestration (`/api/v1/submissions`)

### 6.1 `POST /api/v1/submissions/drafts`
Initialize a submission in `DRAFT` state for an active campaign. Requires `CONTRIBUTOR` capability.

### 6.2 `PUT /api/v1/submissions/drafts/{id}`
Update submission payload or metadata before finalization.

### 6.3 `POST /api/v1/submissions/drafts/{id}/upload-url`
Request presigned S3 upload URL. Validates MIME type and file size against campaign requirements.
- **Request Body:**
  ```json
  {
    "filename": "speech_sample.wav",
    "mime_type": "audio/wav",
    "byte_size": 1500000,
    "asset_type": "AUDIO"
  }
  ```
- **Response `200 OK`:**
  ```json
  {
    "submission_id": "...",
    "upload_url": "https://storage.datamint.ai/datamint-private-submissions/campaigns/.../speech_sample.wav?expires=...",
    "storage_key": "campaigns/.../speech_sample.wav",
    "expires_at": "2026-11-18T14:30:00Z"
  }
  ```

### 6.4 `POST /api/v1/submissions/drafts/{id}/confirm-upload`
Confirm that direct client upload to S3 has finished.

### 6.5 `POST /api/v1/submissions/drafts/{id}/submit`
Finalize submission and transition to `PENDING_VALIDATION`. Enforces concurrency-safe capacity bounds via PostgreSQL row-level locks (`with_for_update`).

### 6.6 `GET /api/v1/submissions/my-submissions`
List submissions authored by the authenticated contributor.

### 6.7 `GET /api/v1/submissions/campaigns/{campaign_id}`
List all submissions for a campaign. Restricted strictly to the campaign creator.

---

## 7. Media Download Access (`/api/v1/media`)

### 7.1 `GET /api/v1/media/submissions/{submission_id}/assets/{asset_id}/download-url`
Generate short-lived presigned download URL for private submission media.
- **Authorization:** Only the submitting contributor or the dataset campaign creator may access the asset. Third parties receive `400 Bad Request` (`FORBIDDEN_MEDIA_ACCESS`).
- **Response `200 OK`:**
  ```json
  {
    "download_url": "https://storage.datamint.ai/datamint-private-submissions/.../speech_sample.wav?expires=...",
    "expires_in_seconds": 1800
  }
  ```
