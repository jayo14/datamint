# DataMint Domain Model

## 1. Domain Entities and Aggregates

The DataMint domain model establishes explicit boundaries between identity, marketplace campaigns, submission workflows, validation pipelines, and financial ledger settlements.

```mermaid
classDiagram
    class User {
        +UUID id
        +String email
        +Boolean is_active
        +DateTime created_at
    }

    class UserProfile {
        +UUID id
        +UUID user_id
        +String display_name
        +String avatar_url
        +String bio
        +JSON reputation_metrics
    }

    class UserCapability {
        +UUID id
        +UUID user_id
        +CapabilityType capability (CONTRIBUTOR, CREATOR, REVIEWER, ADMIN)
        +Boolean is_enabled
    }

    class Wallet {
        +UUID id
        +UUID user_id
        +String address
        +Int chain_id
        +Boolean is_primary
        +DateTime verified_at
    }

    class DatasetCampaign {
        +UUID id
        +UUID creator_id
        +String title
        +String description
        +DataType data_type (TEXT, VOICE, IMAGE)
        +CampaignStatus status
        +Int target_submissions
        +Int current_submissions
        +Decimal reward_per_submission
        +String reward_currency
    }

    class CampaignRequirement {
        +UUID id
        +UUID campaign_id
        +JSON schema_definition
        +Int min_duration_sec
        +Int max_duration_sec
        +JSON quality_criteria
    }

    class Submission {
        +UUID id
        +UUID campaign_id
        +UUID contributor_id
        +SubmissionStatus status
        +Int attempt_number
        +DateTime submitted_at
    }

    class SubmissionAsset {
        +UUID id
        +UUID submission_id
        +AssetType asset_type
        +String storage_key
        +Int byte_size
        +String mime_type
        +String checksum_sha256
    }

    class ValidationRun {
        +UUID id
        +UUID submission_id
        +String validator_type
        +ValidationStatus status
        +Decimal score
        +JSON raw_output
        +DateTime completed_at
    }

    class EscrowCampaign {
        +UUID id
        +UUID campaign_id
        +String onchain_campaign_id
        +Decimal total_funded
        +Decimal total_claimed
        +Decimal total_reserved
        +Decimal total_available
        +Decimal total_refunded
    }

    class LedgerEntry {
        +UUID id
        +UUID escrow_campaign_id
        +EntryType entry_type
        +Decimal amount
        +Decimal running_available
        +Decimal running_reserved
        +Decimal running_claimed
        +Decimal running_refunded
        +String reference_id
        +DateTime created_at
    }

    class PayoutAuthorization {
        +UUID id
        +UUID submission_id
        +UUID contributor_id
        +Decimal amount
        +String voucher_hash
        +String signature
        +PayoutStatus status
        +DateTime expires_at
    }

    User "1" --> "1" UserProfile : owns
    User "1" --> "*" UserCapability : holds
    User "1" --> "*" Wallet : connects
    User "1" --> "*" DatasetCampaign : creates
    User "1" --> "*" Submission : submits

    DatasetCampaign "1" --> "1" CampaignRequirement : specifies
    DatasetCampaign "1" --> "1" EscrowCampaign : funded_by
    DatasetCampaign "1" --> "*" Submission : collects

    Submission "1" --> "*" SubmissionAsset : contains
    Submission "1" --> "*" ValidationRun : evaluated_by
    Submission "1" --> "0..1" PayoutAuthorization : produces

    EscrowCampaign "1" --> "*" LedgerEntry : records
```

---

## 2. Entity Lifecycle & Invariants

### 2.1 Identity & Capabilities
- **Capability Independence:** `UserCapability` records whether a user is authorized for `CONTRIBUTOR`, `CREATOR`, `REVIEWER`, or `ADMIN` roles. An individual account holds multiple capabilities concurrently.
- **Wallet Ownership:** A user must authenticate ownership of each wallet via EIP-4361 signature verification before the wallet is activated for payouts or campaign funding.

### 2.2 Campaigns & Escrow Alignment
- A `DatasetCampaign` starts in `DRAFT`.
- A campaign CANNOT transition to `ACTIVE` until `EscrowCampaign` records an on-chain deposit event confirmed by the ledger.
- While `ACTIVE`, the reward per submission is frozen. Modifying the reward requires creating a new campaign version to protect contributor trust.

### 2.3 Submissions & Validation Pipeline
- Submissions are created in `PENDING_UPLOAD`. Once client uploads the media asset directly to S3 and signals completion, status transitions to `QUEUED_FOR_VALIDATION`.
- An asynchronous worker dispatches the submission to an AI validator (or automated rule engine).
- If validation passes (`score >= threshold`), submission transitions to `APPROVED`, automatically allocating a payout reservation in the financial ledger.
- If validation is borderline or flagged, status transitions to `NEEDS_REVIEW`.
- If rejected, contributor may view specific findings and optionally appeal.

### 2.4 Payout Authorizations & Claims
- Upon `APPROVED` state, a `PayoutAuthorization` (cryptographic EIP-712 voucher) is generated and signed by the platform operator key.
- The contributor executes a pull-payment transaction on Celo by submitting the voucher to `DataMintEscrow.sol`.
- Upon on-chain confirmation, the submission transitions to `SETTLED`, and the ledger marks the reserved amount as `CLAIMED`.
