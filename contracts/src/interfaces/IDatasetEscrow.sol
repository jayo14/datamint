// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/**
 * @title IDatasetEscrow
 * @notice Public interface for DataMint's on-chain dataset campaign escrow and EIP-712 reward distribution system.
 */
interface IDatasetEscrow {
    // --- Data Structures ---

    enum CampaignState {
        NON_EXISTENT,
        CREATED,       // Initialized by creator, awaiting full upfront funding
        ACTIVE,        // Fully funded, accepting submissions and claims
        PAUSED,        // Temporarily paused by creator or admin
        CANCELLED,     // Cancelled by creator or admin; claims frozen or grace period
        CLOSED         // Target rewards reached or final refund executed; completed
    }

    struct Campaign {
        bytes32 campaignId;          // Unique campaign identifier (hash of UUID)
        address creator;             // Creator address
        uint256 rewardPerSubmission; // Exact reward per valid submission in cUSD base units
        uint256 maxSubmissions;      // Target maximum number of rewards
        uint256 totalBudget;         // Required budget = rewardPerSubmission * maxSubmissions
        uint256 fundedAmount;        // Total deposited by creator
        uint256 claimedAmount;       // Total withdrawn by contributors
        uint256 claimedCount;        // Number of rewards claimed
        uint256 refundedAmount;      // Total refunded back to creator
        uint256 claimDeadline;       // Absolute timestamp after which no vouchers can be claimed
        CampaignState state;         // Current lifecycle state
        bytes32 metadataHash;        // IPFS/Content hash of requirements and criteria
    }

    struct RewardAuthorization {
        bytes32 campaignId;
        address contributor;
        uint256 amount;
        bytes32 nonce;
        uint256 deadline;
    }

    // --- Events ---

    event CampaignCreated(
        bytes32 indexed campaignId,
        address indexed creator,
        uint256 rewardPerSubmission,
        uint256 maxSubmissions,
        uint256 totalBudget,
        uint256 claimDeadline,
        bytes32 metadataHash
    );

    event CampaignFunded(
        bytes32 indexed campaignId,
        address indexed funder,
        uint256 amount,
        uint256 totalFunded
    );

    event CampaignActivated(bytes32 indexed campaignId, uint256 activatedAt);

    event CampaignPaused(bytes32 indexed campaignId, address indexed account);

    event CampaignUnpaused(bytes32 indexed campaignId, address indexed account);

    event RewardClaimed(
        bytes32 indexed campaignId,
        address indexed contributor,
        uint256 amount,
        bytes32 indexed nonce,
        bytes32 voucherHash
    );

    event CampaignCancelled(
        bytes32 indexed campaignId,
        address indexed account,
        string reason
    );

    event CampaignRefunded(
        bytes32 indexed campaignId,
        address indexed recipient,
        uint256 amount,
        uint256 remainingFunded
    );

    event CampaignClosed(
        bytes32 indexed campaignId,
        uint256 totalPaid,
        uint256 totalRefunded
    );

    // --- Custom Errors ---

    error ZeroAddress();
    error ZeroAmount();
    error InvalidCampaignConfiguration(string reason);
    error CampaignAlreadyExists(bytes32 campaignId);
    error CampaignNotFound(bytes32 campaignId);
    error CampaignNotActive(bytes32 campaignId, CampaignState currentState);
    error CampaignAlreadyActive(bytes32 campaignId);
    error CampaignAlreadyFunded(bytes32 campaignId);
    error InsufficientFunding(uint256 provided, uint256 required);
    error UnauthorizedCaller(address caller);
    error InvalidSignature();
    error SignatureExpired(uint256 deadline, uint256 currentTimestamp);
    error CampaignClaimDeadlinePassed(uint256 claimDeadline, uint256 currentTimestamp);
    error VoucherAlreadyExecuted(bytes32 voucherHash);
    error NonceAlreadyUsed(bytes32 nonce);
    error MaxSubmissionsExceeded(uint256 claimed, uint256 max);
    error NoRefundAvailable(bytes32 campaignId);
    error RefundCooldownActive(uint256 claimDeadline, uint256 currentTimestamp);
    error InvalidClaimAmount(uint256 expected, uint256 actual);
    error RecipientMismatch(address expected, address actual);

    // --- Core Functions ---

    function createCampaign(
        bytes32 campaignId,
        uint256 rewardPerSubmission,
        uint256 maxSubmissions,
        uint256 claimDurationSeconds,
        bytes32 metadataHash
    ) external returns (bytes32);

    function fundAndActivateCampaign(bytes32 campaignId) external;

    function createAndFundCampaign(
        bytes32 campaignId,
        uint256 rewardPerSubmission,
        uint256 maxSubmissions,
        uint256 claimDurationSeconds,
        bytes32 metadataHash
    ) external returns (bytes32);

    function claimReward(
        RewardAuthorization calldata auth,
        bytes calldata signature
    ) external;

    function pauseCampaign(bytes32 campaignId) external;

    function unpauseCampaign(bytes32 campaignId) external;

    function cancelCampaign(bytes32 campaignId, string calldata reason) external;

    function refundUnallocatedFunds(bytes32 campaignId) external returns (uint256);

    // --- View Functions ---

    function getCampaign(bytes32 campaignId) external view returns (Campaign memory);

    function isVoucherExecuted(bytes32 voucherHash) external view returns (bool);

    function isNonceUsed(bytes32 nonce) external view returns (bool);

    function getRefundableAmount(bytes32 campaignId) external view returns (uint256);
}
