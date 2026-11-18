// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {IDatasetEscrow} from "./interfaces/IDatasetEscrow.sol";

/**
 * @title DatasetEscrow
 * @author DataMint Platform
 * @notice Production smart contract for managing decentralized dataset campaign escrow,
 *         upfront cUSD budget lockup, EIP-712 cryptographically signed reward claims,
 *         and deterministic refund settlement on Celo.
 */
contract DatasetEscrow is IDatasetEscrow, AccessControl, ReentrancyGuard, EIP712 {
    using SafeERC20 for IERC20;

    // --- Roles ---
    bytes32 public constant SIGNER_ROLE = keccak256("SIGNER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    // --- EIP-712 TypeHash ---
    bytes32 public constant REWARD_AUTHORIZATION_TYPEHASH = keccak256(
        "RewardAuthorization(bytes32 campaignId,address contributor,uint256 amount,bytes32 nonce,uint256 deadline)"
    );

    // --- Constants ---
    uint256 public constant MIN_CLAIM_DURATION = 1 hours;
    uint256 public constant MAX_CLAIM_DURATION = 365 days;
    uint256 public constant CANCELLATION_COOLDOWN = 3 days;

    // --- Immutables & State ---
    IERC20 public immutable cusdToken;

    mapping(bytes32 => Campaign) internal _campaigns;
    mapping(bytes32 => bool) internal _executedVouchers;
    mapping(bytes32 => bool) internal _usedNonces;
    mapping(bytes32 => uint256) public campaignCancelledAt;
    mapping(bytes32 => uint256) public campaignClaimDuration;

    // --- Modifiers ---

    modifier onlyCreator(bytes32 campaignId) {
        if (_campaigns[campaignId].creator != msg.sender) {
            revert UnauthorizedCaller(msg.sender);
        }
        _;
    }

    modifier campaignExists(bytes32 campaignId) {
        if (_campaigns[campaignId].state == CampaignState.NON_EXISTENT) {
            revert CampaignNotFound(campaignId);
        }
        _;
    }

    /**
     * @notice Constructor initializes the escrow contract.
     * @param _cusdToken Address of the cUSD ERC20 token on Celo.
     * @param admin Default administrator account.
     * @param initialSigner Account authorized to sign EIP-712 vouchers.
     */
    constructor(
        address _cusdToken,
        address admin,
        address initialSigner
    ) EIP712("DataMint DatasetEscrow", "1") {
        if (_cusdToken == address(0) || admin == address(0) || initialSigner == address(0)) {
            revert ZeroAddress();
        }

        cusdToken = IERC20(_cusdToken);

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(PAUSER_ROLE, admin);
        _grantRole(SIGNER_ROLE, initialSigner);
    }

    // --- Campaign Lifecycle Functions ---

    /**
     * @notice Initialize a new campaign in CREATED status before funding.
     */
    function createCampaign(
        bytes32 campaignId,
        uint256 rewardPerSubmission,
        uint256 maxSubmissions,
        uint256 claimDurationSeconds,
        bytes32 metadataHash
    ) public returns (bytes32) {
        if (campaignId == bytes32(0)) {
            revert InvalidCampaignConfiguration("Campaign ID cannot be empty");
        }
        if (_campaigns[campaignId].state != CampaignState.NON_EXISTENT) {
            revert CampaignAlreadyExists(campaignId);
        }
        if (rewardPerSubmission == 0) {
            revert ZeroAmount();
        }
        if (maxSubmissions == 0) {
            revert InvalidCampaignConfiguration("Max submissions must be > 0");
        }
        if (claimDurationSeconds < MIN_CLAIM_DURATION || claimDurationSeconds > MAX_CLAIM_DURATION) {
            revert InvalidCampaignConfiguration("Invalid claim duration");
        }
        if (metadataHash == bytes32(0)) {
            revert InvalidCampaignConfiguration("Metadata hash cannot be empty");
        }

        uint256 totalBudget = rewardPerSubmission * maxSubmissions;

        _campaigns[campaignId] = Campaign({
            campaignId: campaignId,
            creator: msg.sender,
            rewardPerSubmission: rewardPerSubmission,
            maxSubmissions: maxSubmissions,
            totalBudget: totalBudget,
            fundedAmount: 0,
            claimedAmount: 0,
            claimedCount: 0,
            refundedAmount: 0,
            claimDeadline: 0,
            state: CampaignState.CREATED,
            metadataHash: metadataHash
        });

        campaignClaimDuration[campaignId] = claimDurationSeconds;

        emit CampaignCreated(
            campaignId,
            msg.sender,
            rewardPerSubmission,
            maxSubmissions,
            totalBudget,
            0,
            metadataHash
        );

        return campaignId;
    }

    /**
     * @notice Fund and activate an initialized campaign by transferring full budget.
     */
    function fundAndActivateCampaign(bytes32 campaignId) public nonReentrant campaignExists(campaignId) {
        Campaign storage campaign = _campaigns[campaignId];

        if (campaign.state != CampaignState.CREATED) {
            revert CampaignAlreadyActive(campaignId);
        }

        uint256 requiredBudget = campaign.totalBudget;

        // Pull full funding upfront
        cusdToken.safeTransferFrom(msg.sender, address(this), requiredBudget);

        campaign.fundedAmount = requiredBudget;
        campaign.claimDeadline = block.timestamp + campaignClaimDuration[campaignId];
        campaign.state = CampaignState.ACTIVE;

        emit CampaignFunded(campaignId, msg.sender, requiredBudget, requiredBudget);
        emit CampaignActivated(campaignId, block.timestamp);
    }

    /**
     * @notice Convenience function to create and fully fund a campaign in a single atomic transaction.
     */
    function createAndFundCampaign(
        bytes32 campaignId,
        uint256 rewardPerSubmission,
        uint256 maxSubmissions,
        uint256 claimDurationSeconds,
        bytes32 metadataHash
    ) external returns (bytes32) {
        createCampaign(
            campaignId,
            rewardPerSubmission,
            maxSubmissions,
            claimDurationSeconds,
            metadataHash
        );
        fundAndActivateCampaign(campaignId);
        return campaignId;
    }

    // --- Reward Claim Functions ---

    /**
     * @notice Claim authorized cUSD reward using a valid EIP-712 platform signature.
     * @param auth The reward authorization parameters.
     * @param signature The cryptographic signature produced by an authorized SIGNER_ROLE account.
     */
    function claimReward(
        RewardAuthorization calldata auth,
        bytes calldata signature
    ) external nonReentrant campaignExists(auth.campaignId) {
        Campaign storage campaign = _campaigns[auth.campaignId];

        // 1. Campaign state verification
        if (campaign.state != CampaignState.ACTIVE) {
            revert CampaignNotActive(auth.campaignId, campaign.state);
        }

        // 2. Caller and recipient verification
        if (msg.sender != auth.contributor) {
            revert RecipientMismatch(auth.contributor, msg.sender);
        }

        // 3. Expiration checks
        if (block.timestamp > auth.deadline) {
            revert SignatureExpired(auth.deadline, block.timestamp);
        }
        if (block.timestamp > campaign.claimDeadline) {
            revert CampaignClaimDeadlinePassed(campaign.claimDeadline, block.timestamp);
        }

        // 4. Amount and capacity verification
        if (auth.amount != campaign.rewardPerSubmission) {
            revert InvalidClaimAmount(campaign.rewardPerSubmission, auth.amount);
        }
        if (campaign.claimedCount >= campaign.maxSubmissions) {
            revert MaxSubmissionsExceeded(campaign.claimedCount, campaign.maxSubmissions);
        }

        // 5. Nonce and voucher replay protection
        if (_usedNonces[auth.nonce]) {
            revert NonceAlreadyUsed(auth.nonce);
        }

        bytes32 structHash = keccak256(
            abi.encode(
                REWARD_AUTHORIZATION_TYPEHASH,
                auth.campaignId,
                auth.contributor,
                auth.amount,
                auth.nonce,
                auth.deadline
            )
        );

        bytes32 digest = _hashTypedDataV4(structHash);

        if (_executedVouchers[digest]) {
            revert VoucherAlreadyExecuted(digest);
        }

        // 6. Signature recovery and verification
        address recoveredSigner = ECDSA.recover(digest, signature);
        if (!hasRole(SIGNER_ROLE, recoveredSigner)) {
            revert InvalidSignature();
        }

        // 7. Effects (Checks-Effects-Interactions)
        _usedNonces[auth.nonce] = true;
        _executedVouchers[digest] = true;

        campaign.claimedAmount += auth.amount;
        campaign.claimedCount += 1;

        if (campaign.claimedCount == campaign.maxSubmissions) {
            campaign.state = CampaignState.CLOSED;
            emit CampaignClosed(auth.campaignId, campaign.claimedAmount, campaign.refundedAmount);
        }

        emit RewardClaimed(auth.campaignId, auth.contributor, auth.amount, auth.nonce, digest);

        // 8. Interactions
        cusdToken.safeTransfer(auth.contributor, auth.amount);
    }

    // --- Campaign Management & Pausing ---

    /**
     * @notice Pause an active campaign. Can be called by creator or account with PAUSER_ROLE.
     */
    function pauseCampaign(bytes32 campaignId) external campaignExists(campaignId) {
        Campaign storage campaign = _campaigns[campaignId];
        if (msg.sender != campaign.creator && !hasRole(PAUSER_ROLE, msg.sender)) {
            revert UnauthorizedCaller(msg.sender);
        }
        if (campaign.state != CampaignState.ACTIVE) {
            revert CampaignNotActive(campaignId, campaign.state);
        }

        campaign.state = CampaignState.PAUSED;
        emit CampaignPaused(campaignId, msg.sender);
    }

    /**
     * @notice Resume a paused campaign.
     */
    function unpauseCampaign(bytes32 campaignId) external campaignExists(campaignId) {
        Campaign storage campaign = _campaigns[campaignId];
        if (msg.sender != campaign.creator && !hasRole(PAUSER_ROLE, msg.sender)) {
            revert UnauthorizedCaller(msg.sender);
        }
        if (campaign.state != CampaignState.PAUSED) {
            revert InvalidCampaignConfiguration("Campaign is not paused");
        }
        if (block.timestamp > campaign.claimDeadline) {
            revert CampaignClaimDeadlinePassed(campaign.claimDeadline, block.timestamp);
        }

        campaign.state = CampaignState.ACTIVE;
        emit CampaignUnpaused(campaignId, msg.sender);
    }

    /**
     * @notice Cancel a campaign. Can be called by creator or admin.
     */
    function cancelCampaign(bytes32 campaignId, string calldata reason) external campaignExists(campaignId) {
        Campaign storage campaign = _campaigns[campaignId];
        if (msg.sender != campaign.creator && !hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) {
            revert UnauthorizedCaller(msg.sender);
        }
        if (campaign.state != CampaignState.ACTIVE && campaign.state != CampaignState.PAUSED) {
            revert InvalidCampaignConfiguration("Campaign cannot be cancelled in current state");
        }

        campaign.state = CampaignState.CANCELLED;
        campaignCancelledAt[campaignId] = block.timestamp;

        emit CampaignCancelled(campaignId, msg.sender, reason);
    }

    /**
     * @notice Refund unallocated funds to campaign creator.
     * Enforces cooldown to allow pending signed vouchers to settle before unspent funds are returned.
     */
    function refundUnallocatedFunds(bytes32 campaignId) external nonReentrant campaignExists(campaignId) onlyCreator(campaignId) returns (uint256) {
        Campaign storage campaign = _campaigns[campaignId];

        if (campaign.state == CampaignState.CLOSED) {
            revert NoRefundAvailable(campaignId);
        }

        uint256 refundable = getRefundableAmount(campaignId);
        if (refundable == 0) {
            revert NoRefundAvailable(campaignId);
        }

        // Refund is permitted if:
        // 1. Campaign is past its claim deadline, OR
        // 2. Campaign was CANCELLED and the CANCELLATION_COOLDOWN period has elapsed.
        bool deadlinePassed = block.timestamp > campaign.claimDeadline;
        bool cooldownElapsed = (campaign.state == CampaignState.CANCELLED) &&
            (block.timestamp >= campaignCancelledAt[campaignId] + CANCELLATION_COOLDOWN);

        if (!deadlinePassed && !cooldownElapsed) {
            revert RefundCooldownActive(
                campaign.state == CampaignState.CANCELLED
                    ? campaignCancelledAt[campaignId] + CANCELLATION_COOLDOWN
                    : campaign.claimDeadline,
                block.timestamp
            );
        }

        // Accounting update
        campaign.refundedAmount += refundable;
        campaign.state = CampaignState.CLOSED;

        emit CampaignRefunded(campaignId, campaign.creator, refundable, campaign.fundedAmount - campaign.claimedAmount - campaign.refundedAmount);
        emit CampaignClosed(campaignId, campaign.claimedAmount, campaign.refundedAmount);

        // Interaction
        cusdToken.safeTransfer(campaign.creator, refundable);

        return refundable;
    }

    // --- View Functions ---

    function getCampaign(bytes32 campaignId) external view returns (Campaign memory) {
        return _campaigns[campaignId];
    }

    function isVoucherExecuted(bytes32 voucherHash) external view returns (bool) {
        return _executedVouchers[voucherHash];
    }

    function isNonceUsed(bytes32 nonce) external view returns (bool) {
        return _usedNonces[nonce];
    }

    function getRefundableAmount(bytes32 campaignId) public view returns (uint256) {
        Campaign storage campaign = _campaigns[campaignId];
        if (campaign.fundedAmount <= campaign.claimedAmount + campaign.refundedAmount) {
            return 0;
        }
        return campaign.fundedAmount - campaign.claimedAmount - campaign.refundedAmount;
    }
}
