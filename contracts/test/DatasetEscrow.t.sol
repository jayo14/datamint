// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {DatasetEscrow} from "../src/DatasetEscrow.sol";
import {IDatasetEscrow} from "../src/interfaces/IDatasetEscrow.sol";
import {MockERC20} from "./mocks/MockERC20.sol";
import {MaliciousToken} from "./mocks/MaliciousToken.sol";
import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

contract DatasetEscrowUnitTest is Test {
    DatasetEscrow public escrow;
    MockERC20 public token;

    address public admin = address(0xAD);
    address public creator = address(0xC1);
    address public contributor1 = address(0xAA1);
    address public contributor2 = address(0xAA2);
    address public unauthorized = address(0xBAD);

    uint256 public signerPrivateKey = 0xA11CE;
    address public platformSigner;

    bytes32 public defaultCampaignId = keccak256("campaign-1");
    uint256 public rewardPerSubmission = 1 ether; // 1 cUSD
    uint256 public maxSubmissions = 5;
    uint256 public claimDuration = 7 days;
    bytes32 public metadataHash = keccak256("ipfs://dataset-metadata-1");

    function setUp() public {
        platformSigner = vm.addr(signerPrivateKey);

        token = new MockERC20("Celo Dollar", "cUSD");
        escrow = new DatasetEscrow(address(token), admin, platformSigner);

        // Fund creator and contributor with mock cUSD
        token.mint(creator, 1000 ether);
        token.mint(contributor1, 10 ether);

        vm.prank(creator);
        token.approve(address(escrow), type(uint256).max);
    }

    // --- Helpers ---

    function _signAuthorization(
        IDatasetEscrow.RewardAuthorization memory auth,
        uint256 privateKey
    ) internal view returns (bytes memory) {
        bytes32 structHash = keccak256(
            abi.encode(
                escrow.REWARD_AUTHORIZATION_TYPEHASH(),
                auth.campaignId,
                auth.contributor,
                auth.amount,
                auth.nonce,
                auth.deadline
            )
        );

        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", _getDomainSeparator(), structHash)
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, digest);
        return abi.encodePacked(r, s, v);
    }

    function _getDomainSeparator() internal view returns (bytes32) {
        return keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes("DataMint DatasetEscrow")),
                keccak256(bytes("1")),
                block.chainid,
                address(escrow)
            )
        );
    }

    // --- Campaign Creation Tests ---

    function test_CreateCampaign_Success() public {
        vm.prank(creator);
        bytes32 cId = escrow.createCampaign(
            defaultCampaignId,
            rewardPerSubmission,
            maxSubmissions,
            claimDuration,
            metadataHash
        );

        assertEq(cId, defaultCampaignId);

        IDatasetEscrow.Campaign memory c = escrow.getCampaign(defaultCampaignId);
        assertEq(c.creator, creator);
        assertEq(c.rewardPerSubmission, rewardPerSubmission);
        assertEq(c.maxSubmissions, maxSubmissions);
        assertEq(c.totalBudget, rewardPerSubmission * maxSubmissions);
        assertEq(c.fundedAmount, 0);
        assertEq(uint8(c.state), uint8(IDatasetEscrow.CampaignState.CREATED));
    }

    function test_CreateCampaign_ZeroReward_Reverts() public {
        vm.prank(creator);
        vm.expectRevert(IDatasetEscrow.ZeroAmount.selector);
        escrow.createCampaign(defaultCampaignId, 0, maxSubmissions, claimDuration, metadataHash);
    }

    function test_CreateCampaign_ZeroMaxSubmissions_Reverts() public {
        vm.prank(creator);
        vm.expectRevert(abi.encodeWithSelector(IDatasetEscrow.InvalidCampaignConfiguration.selector, "Max submissions must be > 0"));
        escrow.createCampaign(defaultCampaignId, rewardPerSubmission, 0, claimDuration, metadataHash);
    }

    function test_CreateCampaign_DuplicateId_Reverts() public {
        vm.prank(creator);
        escrow.createCampaign(defaultCampaignId, rewardPerSubmission, maxSubmissions, claimDuration, metadataHash);

        vm.prank(creator);
        vm.expectRevert(abi.encodeWithSelector(IDatasetEscrow.CampaignAlreadyExists.selector, defaultCampaignId));
        escrow.createCampaign(defaultCampaignId, rewardPerSubmission, maxSubmissions, claimDuration, metadataHash);
    }

    // --- Campaign Funding & Activation Tests ---

    function test_FundAndActivateCampaign_Success() public {
        vm.prank(creator);
        escrow.createCampaign(defaultCampaignId, rewardPerSubmission, maxSubmissions, claimDuration, metadataHash);

        uint256 requiredBudget = rewardPerSubmission * maxSubmissions;
        uint256 balanceBefore = token.balanceOf(creator);

        vm.prank(creator);
        escrow.fundAndActivateCampaign(defaultCampaignId);

        assertEq(token.balanceOf(creator), balanceBefore - requiredBudget);
        assertEq(token.balanceOf(address(escrow)), requiredBudget);

        IDatasetEscrow.Campaign memory c = escrow.getCampaign(defaultCampaignId);
        assertEq(c.fundedAmount, requiredBudget);
        assertEq(uint8(c.state), uint8(IDatasetEscrow.CampaignState.ACTIVE));
        assertEq(c.claimDeadline, block.timestamp + claimDuration);
    }

    function test_CreateAndFundCampaign_Atomic() public {
        uint256 requiredBudget = rewardPerSubmission * maxSubmissions;
        uint256 balanceBefore = token.balanceOf(creator);

        vm.prank(creator);
        bytes32 cId = escrow.createAndFundCampaign(
            defaultCampaignId,
            rewardPerSubmission,
            maxSubmissions,
            claimDuration,
            metadataHash
        );

        assertEq(cId, defaultCampaignId);
        assertEq(token.balanceOf(creator), balanceBefore - requiredBudget);

        IDatasetEscrow.Campaign memory c = escrow.getCampaign(defaultCampaignId);
        assertEq(uint8(c.state), uint8(IDatasetEscrow.CampaignState.ACTIVE));
    }

    // --- Reward Claiming Tests ---

    function test_ClaimReward_Success() public {
        vm.prank(creator);
        escrow.createAndFundCampaign(defaultCampaignId, rewardPerSubmission, maxSubmissions, claimDuration, metadataHash);

        bytes32 nonce = keccak256("nonce-1");
        uint256 deadline = block.timestamp + 1 hours;

        IDatasetEscrow.RewardAuthorization memory auth = IDatasetEscrow.RewardAuthorization({
            campaignId: defaultCampaignId,
            contributor: contributor1,
            amount: rewardPerSubmission,
            nonce: nonce,
            deadline: deadline
        });

        bytes memory sig = _signAuthorization(auth, signerPrivateKey);

        uint256 balanceBefore = token.balanceOf(contributor1);

        vm.prank(contributor1);
        escrow.claimReward(auth, sig);

        assertEq(token.balanceOf(contributor1), balanceBefore + rewardPerSubmission);

        IDatasetEscrow.Campaign memory c = escrow.getCampaign(defaultCampaignId);
        assertEq(c.claimedCount, 1);
        assertEq(c.claimedAmount, rewardPerSubmission);
        assertTrue(escrow.isNonceUsed(nonce));
    }

    function test_ClaimReward_DuplicateReplay_Reverts() public {
        vm.prank(creator);
        escrow.createAndFundCampaign(defaultCampaignId, rewardPerSubmission, maxSubmissions, claimDuration, metadataHash);

        bytes32 nonce = keccak256("nonce-replay");
        IDatasetEscrow.RewardAuthorization memory auth = IDatasetEscrow.RewardAuthorization({
            campaignId: defaultCampaignId,
            contributor: contributor1,
            amount: rewardPerSubmission,
            nonce: nonce,
            deadline: block.timestamp + 1 hours
        });

        bytes memory sig = _signAuthorization(auth, signerPrivateKey);

        vm.prank(contributor1);
        escrow.claimReward(auth, sig);

        // Second claim attempt with exact same authorization
        vm.prank(contributor1);
        vm.expectRevert(abi.encodeWithSelector(IDatasetEscrow.NonceAlreadyUsed.selector, nonce));
        escrow.claimReward(auth, sig);
    }

    function test_ClaimReward_UnauthorizedSigner_Reverts() public {
        vm.prank(creator);
        escrow.createAndFundCampaign(defaultCampaignId, rewardPerSubmission, maxSubmissions, claimDuration, metadataHash);

        uint256 badPrivateKey = 0xBAD519;
        IDatasetEscrow.RewardAuthorization memory auth = IDatasetEscrow.RewardAuthorization({
            campaignId: defaultCampaignId,
            contributor: contributor1,
            amount: rewardPerSubmission,
            nonce: keccak256("nonce-bad-signer"),
            deadline: block.timestamp + 1 hours
        });

        bytes memory sig = _signAuthorization(auth, badPrivateKey);

        vm.prank(contributor1);
        vm.expectRevert(IDatasetEscrow.InvalidSignature.selector);
        escrow.claimReward(auth, sig);
    }

    function test_ClaimReward_ExpiredSignature_Reverts() public {
        vm.prank(creator);
        escrow.createAndFundCampaign(defaultCampaignId, rewardPerSubmission, maxSubmissions, claimDuration, metadataHash);

        uint256 expiredDeadline = block.timestamp + 10 minutes;
        IDatasetEscrow.RewardAuthorization memory auth = IDatasetEscrow.RewardAuthorization({
            campaignId: defaultCampaignId,
            contributor: contributor1,
            amount: rewardPerSubmission,
            nonce: keccak256("nonce-expired"),
            deadline: expiredDeadline
        });

        bytes memory sig = _signAuthorization(auth, signerPrivateKey);

        // Fast-forward past deadline
        vm.warp(expiredDeadline + 1);

        vm.prank(contributor1);
        vm.expectRevert(abi.encodeWithSelector(IDatasetEscrow.SignatureExpired.selector, expiredDeadline, block.timestamp));
        escrow.claimReward(auth, sig);
    }

    function test_ClaimReward_RecipientMismatch_Reverts() public {
        vm.prank(creator);
        escrow.createAndFundCampaign(defaultCampaignId, rewardPerSubmission, maxSubmissions, claimDuration, metadataHash);

        IDatasetEscrow.RewardAuthorization memory auth = IDatasetEscrow.RewardAuthorization({
            campaignId: defaultCampaignId,
            contributor: contributor1,
            amount: rewardPerSubmission,
            nonce: keccak256("nonce-mismatch"),
            deadline: block.timestamp + 1 hours
        });

        bytes memory sig = _signAuthorization(auth, signerPrivateKey);

        // Unauthorized caller attempts to claim contributor1's reward
        vm.prank(unauthorized);
        vm.expectRevert(abi.encodeWithSelector(IDatasetEscrow.RecipientMismatch.selector, contributor1, unauthorized));
        escrow.claimReward(auth, sig);
    }

    // --- Campaign Pausing Tests ---

    function test_PauseAndUnpauseCampaign() public {
        vm.prank(creator);
        escrow.createAndFundCampaign(defaultCampaignId, rewardPerSubmission, maxSubmissions, claimDuration, metadataHash);

        vm.prank(creator);
        escrow.pauseCampaign(defaultCampaignId);

        IDatasetEscrow.Campaign memory c = escrow.getCampaign(defaultCampaignId);
        assertEq(uint8(c.state), uint8(IDatasetEscrow.CampaignState.PAUSED));

        // Claim should fail while paused
        IDatasetEscrow.RewardAuthorization memory auth = IDatasetEscrow.RewardAuthorization({
            campaignId: defaultCampaignId,
            contributor: contributor1,
            amount: rewardPerSubmission,
            nonce: keccak256("nonce-paused"),
            deadline: block.timestamp + 1 hours
        });
        bytes memory sig = _signAuthorization(auth, signerPrivateKey);

        vm.prank(contributor1);
        vm.expectRevert(abi.encodeWithSelector(IDatasetEscrow.CampaignNotActive.selector, defaultCampaignId, IDatasetEscrow.CampaignState.PAUSED));
        escrow.claimReward(auth, sig);

        // Unpause
        vm.prank(creator);
        escrow.unpauseCampaign(defaultCampaignId);

        c = escrow.getCampaign(defaultCampaignId);
        assertEq(uint8(c.state), uint8(IDatasetEscrow.CampaignState.ACTIVE));

        // Now claim succeeds
        vm.prank(contributor1);
        escrow.claimReward(auth, sig);
        assertEq(token.balanceOf(contributor1), 10 ether + rewardPerSubmission);
    }

    // --- Cancellation and Refunds Tests ---

    function test_CancelCampaign_And_RefundUnallocated() public {
        vm.prank(creator);
        escrow.createAndFundCampaign(defaultCampaignId, rewardPerSubmission, 5, claimDuration, metadataHash);

        // Claim 1 submission (1 cUSD out of 5 cUSD)
        IDatasetEscrow.RewardAuthorization memory auth = IDatasetEscrow.RewardAuthorization({
            campaignId: defaultCampaignId,
            contributor: contributor1,
            amount: rewardPerSubmission,
            nonce: keccak256("nonce-refund-test"),
            deadline: block.timestamp + 1 hours
        });
        bytes memory sig = _signAuthorization(auth, signerPrivateKey);

        vm.prank(contributor1);
        escrow.claimReward(auth, sig);

        // Creator cancels remaining campaign
        vm.prank(creator);
        escrow.cancelCampaign(defaultCampaignId, "Target dataset revised");

        IDatasetEscrow.Campaign memory c = escrow.getCampaign(defaultCampaignId);
        assertEq(uint8(c.state), uint8(IDatasetEscrow.CampaignState.CANCELLED));

        // Refund during cooldown fails
        vm.prank(creator);
        vm.expectRevert();
        escrow.refundUnallocatedFunds(defaultCampaignId);

        // Warp past cancellation cooldown (3 days)
        vm.warp(block.timestamp + 3 days + 1);

        uint256 creatorBalanceBefore = token.balanceOf(creator);
        uint256 expectedRefund = 4 ether; // 5 ether funded - 1 ether claimed

        vm.prank(creator);
        uint256 refunded = escrow.refundUnallocatedFunds(defaultCampaignId);

        assertEq(refunded, expectedRefund);
        assertEq(token.balanceOf(creator), creatorBalanceBefore + expectedRefund);

        c = escrow.getCampaign(defaultCampaignId);
        assertEq(c.refundedAmount, expectedRefund);
        assertEq(uint8(c.state), uint8(IDatasetEscrow.CampaignState.CLOSED));

        // Second refund attempt fails
        vm.prank(creator);
        vm.expectRevert(abi.encodeWithSelector(IDatasetEscrow.NoRefundAvailable.selector, defaultCampaignId));
        escrow.refundUnallocatedFunds(defaultCampaignId);
    }

    // --- Security: Signer Role Revocation ---

    function test_RevokedSigner_InvalidatesPendingVouchers() public {
        vm.prank(creator);
        escrow.createAndFundCampaign(defaultCampaignId, rewardPerSubmission, maxSubmissions, claimDuration, metadataHash);

        IDatasetEscrow.RewardAuthorization memory auth = IDatasetEscrow.RewardAuthorization({
            campaignId: defaultCampaignId,
            contributor: contributor1,
            amount: rewardPerSubmission,
            nonce: keccak256("nonce-revocation"),
            deadline: block.timestamp + 1 hours
        });
        bytes memory sig = _signAuthorization(auth, signerPrivateKey);

        // Admin revokes platform signer role
        bytes32 signerRole = escrow.SIGNER_ROLE();
        vm.prank(admin);
        escrow.revokeRole(signerRole, platformSigner);

        // Attempt claim -> should revert with InvalidSignature
        vm.prank(contributor1);
        vm.expectRevert(IDatasetEscrow.InvalidSignature.selector);
        escrow.claimReward(auth, sig);
    }

    // --- Security: Reentrancy Protection ---

    function test_Reentrancy_Blocked() public {
        MaliciousToken malToken = new MaliciousToken();
        DatasetEscrow malEscrow = new DatasetEscrow(address(malToken), admin, platformSigner);

        malToken.mint(creator, 100 ether);
        vm.prank(creator);
        malToken.approve(address(malEscrow), type(uint256).max);

        bytes32 malCampaignId = keccak256("mal-campaign");
        vm.prank(creator);
        malEscrow.createAndFundCampaign(malCampaignId, 1 ether, 5, 7 days, metadataHash);

        IDatasetEscrow.RewardAuthorization memory auth = IDatasetEscrow.RewardAuthorization({
            campaignId: malCampaignId,
            contributor: contributor1,
            amount: 1 ether,
            nonce: keccak256("mal-nonce"),
            deadline: block.timestamp + 1 hours
        });

        // Sign digest for malEscrow
        bytes32 structHash = keccak256(
            abi.encode(
                malEscrow.REWARD_AUTHORIZATION_TYPEHASH(),
                auth.campaignId,
                auth.contributor,
                auth.amount,
                auth.nonce,
                auth.deadline
            )
        );
        bytes32 domainSep = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes("DataMint DatasetEscrow")),
                keccak256(bytes("1")),
                block.chainid,
                address(malEscrow)
            )
        );
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSep, structHash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPrivateKey, digest);
        bytes memory sig = abi.encodePacked(r, s, v);

        // Arm token to attempt reentrant claim inside transfer()
        malToken.setReentrancyConfig(address(malEscrow), auth, sig);

        // Expect revert due to ReentrancyGuardReentrantCall
        vm.prank(contributor1);
        vm.expectRevert();
        malEscrow.claimReward(auth, sig);
    }

    // --- Pre-Mainnet Invariant & Authorization Edge Cases ---

    function test_ClaimReward_CrossCampaignReplay_Reverts() public {
        bytes32 campaign2Id = keccak256("campaign-2");
        vm.startPrank(creator);
        escrow.createAndFundCampaign(defaultCampaignId, rewardPerSubmission, maxSubmissions, claimDuration, metadataHash);
        escrow.createAndFundCampaign(campaign2Id, rewardPerSubmission, maxSubmissions, claimDuration, metadataHash);
        vm.stopPrank();

        bytes32 nonce = keccak256("nonce-cross-replay");
        IDatasetEscrow.RewardAuthorization memory auth = IDatasetEscrow.RewardAuthorization({
            campaignId: defaultCampaignId,
            contributor: contributor1,
            amount: rewardPerSubmission,
            nonce: nonce,
            deadline: block.timestamp + 1 hours
        });

        // Valid signature for defaultCampaignId
        bytes memory sig = _signAuthorization(auth, signerPrivateKey);

        // Contributor attempts to submit the voucher targeting campaign2Id
        auth.campaignId = campaign2Id;
        vm.prank(contributor1);
        vm.expectRevert(IDatasetEscrow.InvalidSignature.selector);
        escrow.claimReward(auth, sig);
    }

    function test_ClaimReward_AmountTampered_Reverts() public {
        vm.prank(creator);
        escrow.createAndFundCampaign(defaultCampaignId, rewardPerSubmission, maxSubmissions, claimDuration, metadataHash);

        bytes32 nonce = keccak256("nonce-amount-tamper");
        IDatasetEscrow.RewardAuthorization memory auth = IDatasetEscrow.RewardAuthorization({
            campaignId: defaultCampaignId,
            contributor: contributor1,
            amount: rewardPerSubmission,
            nonce: nonce,
            deadline: block.timestamp + 1 hours
        });

        bytes memory sig = _signAuthorization(auth, signerPrivateKey);

        // Tamper with the amount to claim double reward
        auth.amount = rewardPerSubmission * 2;
        vm.prank(contributor1);
        // Reverts with InvalidClaimAmount because contract enforces strict campaign reward consistency
        vm.expectRevert(
            abi.encodeWithSelector(IDatasetEscrow.InvalidClaimAmount.selector, rewardPerSubmission, rewardPerSubmission * 2)
        );
        escrow.claimReward(auth, sig);
    }

    function test_Cancellation_CannotRefundCommittedClaims() public {
        vm.prank(creator);
        escrow.createAndFundCampaign(defaultCampaignId, rewardPerSubmission, 2, claimDuration, metadataHash);

        // 1 claim is completed
        bytes32 nonce = keccak256("nonce-committed-claim");
        IDatasetEscrow.RewardAuthorization memory auth = IDatasetEscrow.RewardAuthorization({
            campaignId: defaultCampaignId,
            contributor: contributor1,
            amount: rewardPerSubmission,
            nonce: nonce,
            deadline: block.timestamp + 1 hours
        });
        bytes memory sig = _signAuthorization(auth, signerPrivateKey);

        vm.prank(contributor1);
        escrow.claimReward(auth, sig);

        // Creator cancels remaining campaign
        vm.prank(creator);
        escrow.cancelCampaign(defaultCampaignId, "Early cancellation");

        // Fast forward past timelock
        vm.warp(block.timestamp + 3 days + 1);

        uint256 refundable = escrow.getRefundableAmount(defaultCampaignId);
        // Total funded: 2 * rewardPerSubmission. Claimed: 1 * rewardPerSubmission.
        // Refundable MUST strictly be 1 * rewardPerSubmission, never refunding claimed funds.
        assertEq(refundable, rewardPerSubmission);

        uint256 creatorBalanceBefore = token.balanceOf(creator);
        vm.prank(creator);
        uint256 refunded = escrow.refundUnallocatedFunds(defaultCampaignId);

        assertEq(refunded, rewardPerSubmission);
        assertEq(token.balanceOf(creator), creatorBalanceBefore + rewardPerSubmission);

        // Subsequent refund attempt yields 0
        assertEq(escrow.getRefundableAmount(defaultCampaignId), 0);
        vm.prank(creator);
        vm.expectRevert(abi.encodeWithSelector(IDatasetEscrow.NoRefundAvailable.selector, defaultCampaignId));
        escrow.refundUnallocatedFunds(defaultCampaignId);
    }
}
