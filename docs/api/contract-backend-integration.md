# DataMint Contract & Backend Integration Guide

This guide specifies how the Phase 1 FastAPI backend interfaces with `DatasetEscrow.sol`.

## 1. Contract Addresses & Configuration

| Network | Chain ID | RPC URL | cUSD Token Address | Escrow Address |
| :--- | :--- | :--- | :--- | :--- |
| **Celo Mainnet** | `42220` | `https://forno.celo.org` | `0x765DE816845861e75A25fCA122bb6898B8B1282a` | *(Pending Production Deploy)* |
| **Celo Sepolia** | `11155420` | `https://forno.celo-sepolia.celo-testnet.org` | *(Testnet cUSD)* | *(Testnet Deploy)* |
| **Local Anvil** | `31337` | `http://127.0.0.1:8545` | `MockERC20` | Local deploy |

---

## 2. Event Signatures & Indexed Topics

The backend blockchain worker listens for the following contract events:

### 2.1 `CampaignFunded`
- **Topic 0:** `keccak256("CampaignFunded(bytes32,address,uint256,uint256)")`
- **Indexed Fields:**
  - `bytes32 indexed campaignId`
  - `address indexed funder`
- **Data:**
  - `uint256 amount`
  - `uint256 totalFunded`
- **Backend Action:**
  - Lookup `DatasetCampaign` by `campaign_id == campaignId`.
  - Transition `status` from `PENDING_FUNDING` to `ACTIVE`.
  - Append immutable row in `ledger_entries`:
    - `entry_type = "DEPOSIT"`
    - `amount = amount / 1e18`
    - `reference_id = "celo:tx:<txHash>:<logIndex>"`
    - Updates `total_funded` and `total_available` in `escrow_campaigns`.

### 2.2 `RewardClaimed`
- **Topic 0:** `keccak256("RewardClaimed(bytes32,address,uint256,bytes32,bytes32)")`
- **Indexed Fields:**
  - `bytes32 indexed campaignId`
  - `address indexed contributor`
  - `bytes32 indexed nonce`
- **Data:**
  - `uint256 amount`
  - `bytes32 voucherHash`
- **Backend Action:**
  - Match `PayoutAuthorization` by `recipient_address == contributor` and `voucher_hash == voucherHash`.
  - Transition `PayoutAuthorization.status` to `CLAIMED`.
  - Transition associated `Submission.status` to `SETTLED`.
  - Append immutable row in `ledger_entries`:
    - `entry_type = "CLAIM"`
    - `amount = amount / 1e18`
    - `reference_id = "celo:claim:<txHash>:<voucherHash>"`
    - Decrements `total_reserved` and increments `total_claimed` in `escrow_campaigns`.

### 2.3 `CampaignRefunded`
- **Topic 0:** `keccak256("CampaignRefunded(bytes32,address,uint256,uint256)")`
- **Indexed Fields:**
  - `bytes32 indexed campaignId`
  - `address indexed recipient`
- **Data:**
  - `uint256 amount`
  - `uint256 remainingFunded`
- **Backend Action:**
  - Append immutable row in `ledger_entries`:
    - `entry_type = "REFUND"`
    - `amount = amount / 1e18`
    - `reference_id = "celo:refund:<txHash>:<logIndex>"`
    - Decrements `total_available` and increments `total_refunded`.
  - Transition `DatasetCampaign.status` to `CLOSED`.

---

## 3. Replay Protection & Reorg Safety

1. **Idempotent Reference IDs:** Every ledger entry must use `reference_id = "celo:<txHash>:<logIndex>"`. Re-processed blocks or duplicated webhook events hit the unique constraint on `ledger_entries.reference_id` and are discarded without double-counting.
2. **Confirmation Threshold:** The indexer requires at least **12 block confirmations** on Celo before confirming a deposit or claim as irreversible.
3. **Reconciliation Checks:** A scheduled cron job compares `escrow.getCampaign(campaignId).claimedAmount` with the database `total_claimed` to alert on any state drift.
