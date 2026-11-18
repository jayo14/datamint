# DataMint Database Design & ERD

## 1. Overview and Relational Principles

The DataMint database is hosted on PostgreSQL 16. It is designed to replace legacy ad-hoc schemas with an ACID-compliant, strictly normalized schema with explicit foreign keys, check constraints, composite uniqueness rules, and audit trails.

### Design Principles:
1. **UUIDv7 / UUID Primary Keys:** All primary keys use UUID to enable distributed generation and prevent enumeration attacks.
2. **Explicit Foreign Keys with Deletion Protection:** Sensitive records (`users`, `campaigns`, `ledger_entries`, `submissions`) enforce `ON DELETE RESTRICT` to prevent accidental orphaned financial or audit records.
3. **Immutable Ledgers:** The `ledger_entries` table is insert-only. Balances are derived or verified against running totals.
4. **Strict Check Constraints:** Non-negative balances, allowed enum strings, and timestamp sequences (`completed_at >= created_at`) are guaranteed at the database engine level.

---

## 2. Entity Relationship Diagram (ERD)

```mermaid
erDiagram
    users ||--o{ user_capabilities : has
    users ||--o| user_profiles : has
    users ||--o{ user_wallets : connects
    users ||--o{ auth_sessions : creates
    users ||--o{ dataset_campaigns : creates
    users ||--o{ submissions : submits

    dataset_campaigns ||--|| campaign_requirements : defines
    dataset_campaigns ||--|| escrow_campaigns : backed_by
    dataset_campaigns ||--o{ submissions : receives

    escrow_campaigns ||--o{ ledger_entries : journals

    submissions ||--o{ submission_assets : contains
    submissions ||--o{ validation_runs : evaluates
    submissions ||--o{ reviews : reviews
    submissions ||--o| payout_authorizations : authorizes

    validation_runs ||--o{ validation_findings : details

    users {
        uuid id PK
        string email UK
        boolean is_active
        timestamptz created_at
        timestamptz updated_at
    }

    user_profiles {
        uuid id PK
        uuid user_id FK,UK
        string display_name
        string avatar_url
        text bio
        jsonb metadata
        timestamptz updated_at
    }

    user_capabilities {
        uuid id PK
        uuid user_id FK
        string capability_type
        boolean is_enabled
        timestamptz granted_at
    }

    user_wallets {
        uuid id PK
        uuid user_id FK
        string address UK
        integer chain_id
        boolean is_primary
        timestamptz verified_at
    }

    dataset_campaigns {
        uuid id PK
        uuid creator_id FK
        string title
        text description
        string data_type
        string status
        integer target_submissions
        integer current_submissions
        numeric reward_per_submission
        string reward_currency
        timestamptz deadline
        timestamptz created_at
        timestamptz updated_at
    }

    campaign_requirements {
        uuid id PK
        uuid campaign_id FK,UK
        jsonb validation_rules
        integer min_duration_sec
        integer max_duration_sec
        jsonb criteria_metadata
    }

    escrow_campaigns {
        uuid id PK
        uuid campaign_id FK,UK
        string onchain_campaign_id UK
        numeric total_funded
        numeric total_claimed
        numeric total_reserved
        numeric total_available
        numeric total_refunded
        timestamptz created_at
        timestamptz updated_at
    }

    ledger_entries {
        uuid id PK
        uuid escrow_campaign_id FK
        string entry_type
        numeric amount
        numeric running_available
        numeric running_reserved
        numeric running_claimed
        numeric running_refunded
        string reference_id UK
        string notes
        timestamptz created_at
    }

    submissions {
        uuid id PK
        uuid campaign_id FK
        uuid contributor_id FK
        string status
        integer attempt_number
        jsonb metadata
        timestamptz submitted_at
        timestamptz updated_at
    }

    submission_assets {
        uuid id PK
        uuid submission_id FK
        string asset_type
        string storage_key UK
        bigint byte_size
        string mime_type
        string checksum_sha256
        timestamptz created_at
    }

    validation_runs {
        uuid id PK
        uuid submission_id FK
        string validator_type
        string status
        numeric score
        jsonb raw_output
        timestamptz created_at
        timestamptz completed_at
    }

    validation_findings {
        uuid id PK
        uuid validation_run_id FK
        string code
        string severity
        text message
        jsonb details
    }

    reviews {
        uuid id PK
        uuid submission_id FK
        uuid reviewer_id FK
        string decision
        text notes
        timestamptz created_at
    }

    payout_authorizations {
        uuid id PK
        uuid submission_id FK,UK
        uuid contributor_id FK
        numeric amount
        string voucher_hash UK
        string signature
        string status
        timestamptz expires_at
        timestamptz created_at
    }
```

---

## 3. Database Indexes and Constraints

### 3.1 Primary Constraints
- `user_wallets.address`: Lowercased unique index to prevent duplicate case-variant registrations.
- `escrow_campaigns.campaign_id`: 1:1 foreign key with `dataset_campaigns`.
- `payout_authorizations.submission_id`: Unique constraint enforcing at most one payout voucher per approved submission.
- `ledger_entries.reference_id`: Unique constraint to prevent duplicate processing of on-chain tx hashes or internal payout UUIDs.

### 3.2 Performance Indexes
- `dataset_campaigns(status, created_at DESC)`: For marketplace querying and filtering.
- `submissions(campaign_id, status)`: For campaign submission counts and progress tracking.
- `submissions(contributor_id, created_at DESC)`: For contributor dashboard history.
- `ledger_entries(escrow_campaign_id, created_at ASC)`: For reconstructing audit trails.
