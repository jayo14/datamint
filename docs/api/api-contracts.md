# DataMint v1 REST API Contracts

All endpoints are served under `/api/v1` and use standard JSON request and response bodies.

## 1. Authentication (`/api/v1/auth`)

### 1.1 `POST /api/v1/auth/nonce`
Generate an EIP-4361 compliant nonce for wallet signing.
- **Request Body:**
  ```json
  {
    "address": "0x742d35Cc6634C0532925a3b844Bc454e4438f44e",
    "chain_id": 42220
  }
  ```
- **Response `200 OK`:**
  ```json
  {
    "nonce": "d8f49a37e1b5c82a",
    "message": "datamint.ai wants you to sign in with your Celo account:\n0x742d35Cc6634C0532925a3b844Bc454e4438f44e\n\nURI: https://datamint.ai\nVersion: 1\nChain ID: 42220\nNonce: d8f49a37e1b5c82a\nIssued At: 2026-11-18T12:00:00Z",
    "expires_at": "2026-11-18T12:05:00Z"
  }
  ```

### 1.2 `POST /api/v1/auth/verify`
Verify signed EIP-4361 message and establish user session.
- **Request Body:**
  ```json
  {
    "message": "datamint.ai wants you to sign in...",
    "signature": "0x304502210089..."
  }
  ```
- **Response `200 OK`:**
  ```json
  {
    "access_token": "eyJhbGciOi...",
    "refresh_token": "eyJhbGciOi...",
    "token_type": "bearer",
    "expires_in": 900,
    "user": {
      "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
      "primary_wallet": "0x742d35cc6634c0532925a3b844bc454e4438f44e",
      "capabilities": ["CONTRIBUTOR", "CREATOR"]
    }
  }
  ```

---

## 2. Campaigns (`/api/v1/campaigns`)

### 2.1 `POST /api/v1/campaigns`
Create a new dataset campaign (in `DRAFT` status). Requires `CREATOR` capability.
- **Request Body:**
  ```json
  {
    "title": "West African English Accents Speech Dataset",
    "description": "Short sentences spoken in Nigerian and Ghanaian accented English for ASR training.",
    "data_type": "VOICE",
    "target_submissions": 500,
    "reward_per_submission": "0.50",
    "reward_currency": "cUSD",
    "requirements": {
      "min_duration_sec": 3,
      "max_duration_sec": 15,
      "audio_format": "audio/wav",
      "instructions": "Speak clearly in a quiet environment reading the prompt displayed."
    }
  }
  ```
- **Response `201 Created`:** Returns created campaign object.

### 2.2 `GET /api/v1/campaigns/{id}`
Fetch detailed campaign information including escrow balance and submission progress.

---

## 3. Marketplace (`/api/v1/marketplace`)

### 3.1 `GET /api/v1/marketplace/tasks`
List publicly discoverable active campaigns open for submission.
- **Query Parameters:** `data_type`, `min_reward`, `page`, `page_size`.
- **Response `200 OK`:** Paginated task list with reward amounts and submission progress bars.

---

## 4. Submissions (`/api/v1/submissions`)

### 4.1 `POST /api/v1/submissions`
Initialize a submission and acquire a pre-signed S3 upload URL.
- **Request Body:**
  ```json
  {
    "campaign_id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
    "filename": "sample_recording.wav",
    "mime_type": "audio/wav",
    "byte_size": 204850
  }
  ```
- **Response `201 Created`:**
  ```json
  {
    "submission_id": "9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d",
    "upload_url": "https://storage.datamint.ai/uploads/...",
    "upload_fields": {},
    "expires_at": "2026-11-18T12:30:00Z"
  }
  ```

### 4.2 `POST /api/v1/submissions/{id}/complete`
Signal that direct S3 upload finished, transitioning state to `QUEUED_FOR_VALIDATION`.

---

## 5. Payments & Payouts (`/api/v1/payments`)

### 5.1 `GET /api/v1/payments/vouchers`
List pending EIP-712 payout vouchers ready for on-chain withdrawal by the current contributor.

### 5.2 `GET /api/v1/payments/ledger/{campaign_id}`
Audit-grade double-entry journal for a campaign's escrow balance. Accessible by the campaign creator and admins.
