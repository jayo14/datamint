# DataMint Smart Contract Architecture & Specification

## 1. Executive Summary

`DatasetEscrow.sol` is the core on-chain financial settlement contract for DataMint. It implements upfront cUSD escrow funding for AI dataset collection campaigns, cryptographically verifiable EIP-712 reward claims for contributors, and deterministic refund settlements on Celo.

The contract enforces the fundamental economic invariant:
$$\text{Total Funded} = \text{Total Claimed} + \text{Total Reserved} + \text{Total Available} + \text{Total Refunded}$$

---

## 2. Contract Architecture & Inheritance

```mermaid
classDiagram
    class AccessControl {
        +hasRole(bytes32, address)
        +grantRole(bytes32, address)
        +revokeRole(bytes32, address)
    }

    class ReentrancyGuard {
        +nonReentrant()
    }

    class EIP712 {
        +_hashTypedDataV4(bytes32)
    }

    class IDatasetEscrow {
        <<interface>>
        +createCampaign(...)
        +fundAndActivateCampaign(...)
        +createAndFundCampaign(...)
        +claimReward(...)
        +pauseCampaign(...)
        +unpauseCampaign(...)
        +cancelCampaign(...)
        +refundUnallocatedFunds(...)
    }

    class DatasetEscrow {
        +IERC20 public immutable cusdToken
        +bytes32 public constant SIGNER_ROLE
        +bytes32 public constant PAUSER_ROLE
        +createCampaign(...)
        +fundAndActivateCampaign(...)
        +createAndFundCampaign(...)
        +claimReward(...)
        +pauseCampaign(...)
        +unpauseCampaign(...)
        +cancelCampaign(...)
        +refundUnallocatedFunds(...)
        +getCampaign(...)
        +getRefundableAmount(...)
    }

    AccessControl <|-- DatasetEscrow
    ReentrancyGuard <|-- DatasetEscrow
    EIP712 <|-- DatasetEscrow
    IDatasetEscrow <|.. DatasetEscrow
```

### 2.1 Dependencies
- **Solidity Version:** `0.8.24` (Cancun EVM, optimized with 200 runs).
- **OpenZeppelin Contracts v5.6.1:**
  - `SafeERC20`: Prevents non-standard ERC20 transfer failures from desynchronizing contract accounting.
  - `AccessControl`: Role-based governance (`DEFAULT_ADMIN_ROLE`, `SIGNER_ROLE`, `PAUSER_ROLE`).
  - `ReentrancyGuard`: Non-reentrancy on all state-changing fund transfers.
  - `EIP712` & `ECDSA`: Standardized cryptographic message digest and signer recovery.

---

## 3. Campaign Lifecycle State Machine

```mermaid
stateDiagram-v2
    [*] --> NON_EXISTENT
    NON_EXISTENT --> CREATED : createCampaign()
    CREATED --> ACTIVE : fundAndActivateCampaign() [Full Budget Locked]
    NON_EXISTENT --> ACTIVE : createAndFundCampaign() [Atomic]

    ACTIVE --> PAUSED : pauseCampaign() [Creator / Pauser]
    PAUSED --> ACTIVE : unpauseCampaign() [Creator / Pauser]

    ACTIVE --> CANCELLED : cancelCampaign() [Creator / Admin]
    PAUSED --> CANCELLED : cancelCampaign() [Creator / Admin]

    ACTIVE --> CLOSED : maxSubmissions reached
    CANCELLED --> CLOSED : refundUnallocatedFunds() [Cooldown passed]
    CLOSED --> [*]
```

---

## 4. EIP-712 Reward Authorization Specification

DataMint decouples compute-heavy off-chain AI validation from on-chain fund distribution. An authorized platform signer produces an EIP-712 signature over a structured authorization.

### 4.1 Domain Separator
```solidity
EIP712Domain {
    string name: "DataMint DatasetEscrow"
    string version: "1"
    uint256 chainId: block.chainid // 42220 for Celo Mainnet
    address verifyingContract: <DatasetEscrow address>
}
```

### 4.2 TypeHash and Struct
```solidity
bytes32 public constant REWARD_AUTHORIZATION_TYPEHASH = keccak256(
    "RewardAuthorization(bytes32 campaignId,address contributor,uint256 amount,bytes32 nonce,uint256 deadline)"
);

struct RewardAuthorization {
    bytes32 campaignId;
    address contributor;
    uint256 amount;
    bytes32 nonce;
    uint256 deadline;
}
```

---

## 5. Sequence Diagrams

### 5.1 Creator Campaign Creation & Full Upfront Funding
```mermaid
sequenceDiagram
    autonumber
    actor Creator as Dataset Creator
    participant Escrow as DatasetEscrow.sol
    participant cUSD as cUSD ERC20 Token

    Creator->>cUSD: approve(DatasetEscrow, requiredBudget)
    Creator->>Escrow: createAndFundCampaign(campaignId, reward, maxSubs, duration, metaHash)
    Escrow->>cUSD: safeTransferFrom(Creator, Escrow, requiredBudget)
    Escrow-->>Escrow: State = ACTIVE, Deadline = block.timestamp + duration
    Escrow-->>Creator: Emit CampaignFunded & CampaignActivated
```

### 5.2 Contributor Reward Claim (Pull Payment)
```mermaid
sequenceDiagram
    autonumber
    actor Contributor as Contributor
    participant Backend as DataMint Backend
    participant Escrow as DatasetEscrow.sol
    participant cUSD as cUSD ERC20 Token

    Contributor->>Backend: Submit Data & S3 Upload Confirmation
    Backend->>Backend: AI Validation (Gemini/Consensus) Passes
    Backend->>Backend: Sign EIP-712 Voucher with SIGNER_ROLE key
    Backend-->>Contributor: Return (RewardAuthorization, signature)
    Contributor->>Escrow: claimReward(auth, signature)
    Escrow->>Escrow: Verify Signature, Nonce, Active State, and Capacity
    Escrow->>Escrow: Mark Nonce Used & Voucher Executed
    Escrow->>cUSD: safeTransfer(Contributor, auth.amount)
    Escrow-->>Contributor: Emit RewardClaimed
```

### 5.3 Campaign Cancellation & Safe Refund
```mermaid
sequenceDiagram
    autonumber
    actor Creator as Dataset Creator
    participant Escrow as DatasetEscrow.sol
    participant cUSD as cUSD ERC20 Token

    Creator->>Escrow: cancelCampaign(campaignId, "Goal reached early")
    Escrow-->>Escrow: State = CANCELLED, cancelledAt = block.timestamp
    Note over Escrow: 3-Day Cancellation Cooldown allows pending claims to settle
    Creator->>Escrow: refundUnallocatedFunds(campaignId) [after cooldown]
    Escrow->>Escrow: refundable = fundedAmount - claimedAmount - refundedAmount
    Escrow->>cUSD: safeTransfer(Creator, refundable)
    Escrow-->>Escrow: State = CLOSED
    Escrow-->>Creator: Emit CampaignRefunded & CampaignClosed
```
