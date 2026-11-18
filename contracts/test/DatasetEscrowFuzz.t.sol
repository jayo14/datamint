// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {DatasetEscrow} from "../src/DatasetEscrow.sol";
import {IDatasetEscrow} from "../src/interfaces/IDatasetEscrow.sol";
import {MockERC20} from "./mocks/MockERC20.sol";

contract DatasetEscrowFuzzTest is Test {
    DatasetEscrow public escrow;
    MockERC20 public token;

    address public admin = address(0xAD);
    address public creator = address(0xC1);
    uint256 public signerPrivateKey = 0xA11CE;
    address public platformSigner;

    function setUp() public {
        platformSigner = vm.addr(signerPrivateKey);
        token = new MockERC20("Celo Dollar", "cUSD");
        escrow = new DatasetEscrow(address(token), admin, platformSigner);

        token.mint(creator, type(uint128).max);
        vm.prank(creator);
        token.approve(address(escrow), type(uint256).max);
    }

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

        bytes32 domainSep = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes("DataMint DatasetEscrow")),
                keccak256(bytes("1")),
                block.chainid,
                address(escrow)
            )
        );

        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSep, structHash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, digest);
        return abi.encodePacked(r, s, v);
    }

    // --- Fuzz: Campaign Creation and Funding Budget Invariant ---

    function testFuzz_CreateAndFundCampaign(
        bytes32 campaignId,
        uint256 rewardPerSubmission,
        uint256 maxSubmissions,
        uint32 claimDuration
    ) public {
        // Bound inputs to reasonable, non-overflowing numbers
        vm.assume(campaignId != bytes32(0));
        rewardPerSubmission = bound(rewardPerSubmission, 1, 100_000 ether);
        maxSubmissions = bound(maxSubmissions, 1, 10_000);
        claimDuration = uint32(bound(claimDuration, escrow.MIN_CLAIM_DURATION(), escrow.MAX_CLAIM_DURATION()));

        uint256 expectedBudget = rewardPerSubmission * maxSubmissions;

        vm.prank(creator);
        escrow.createAndFundCampaign(
            campaignId,
            rewardPerSubmission,
            maxSubmissions,
            claimDuration,
            keccak256("meta")
        );

        IDatasetEscrow.Campaign memory c = escrow.getCampaign(campaignId);
        assertEq(c.totalBudget, expectedBudget);
        assertEq(c.fundedAmount, expectedBudget);
        assertEq(c.claimedAmount, 0);
        assertEq(c.refundedAmount, 0);
        assertEq(uint8(c.state), uint8(IDatasetEscrow.CampaignState.ACTIVE));
        assertEq(c.claimDeadline, block.timestamp + claimDuration);
    }

    // --- Fuzz: Arbitrary Claims Never Exceed Campaign Budget ---

    function testFuzz_ClaimsNeverExceedBudget(
        uint256 reward,
        uint8 maxSubmissionsRaw,
        uint8 claimsToAttempt
    ) public {
        reward = bound(reward, 1 ether, 50 ether);
        uint256 maxSubs = bound(maxSubmissionsRaw, 1, 10);
        uint256 attempts = bound(claimsToAttempt, 1, 15);

        bytes32 cId = keccak256(abi.encodePacked("fuzz-claim", reward, maxSubs));

        vm.prank(creator);
        escrow.createAndFundCampaign(cId, reward, maxSubs, 14 days, keccak256("meta"));

        uint256 successfulClaims = 0;

        for (uint256 i = 0; i < attempts; i++) {
            address contributor = address(uint160(0x1000 + i));
            bytes32 nonce = keccak256(abi.encodePacked("nonce", i, cId));

            IDatasetEscrow.RewardAuthorization memory auth = IDatasetEscrow.RewardAuthorization({
                campaignId: cId,
                contributor: contributor,
                amount: reward,
                nonce: nonce,
                deadline: block.timestamp + 1 hours
            });
            bytes memory sig = _signAuthorization(auth, signerPrivateKey);

            if (successfulClaims < maxSubs) {
                vm.prank(contributor);
                escrow.claimReward(auth, sig);
                successfulClaims++;
                assertEq(token.balanceOf(contributor), reward);
            } else {
                // If maxSubmissions reached, state is CLOSED or reverts MaxSubmissionsExceeded
                vm.prank(contributor);
                vm.expectRevert();
                escrow.claimReward(auth, sig);
            }
        }

        IDatasetEscrow.Campaign memory c = escrow.getCampaign(cId);
        assertEq(c.claimedCount, successfulClaims);
        assertEq(c.claimedAmount, successfulClaims * reward);
        assertLe(c.claimedAmount, c.totalBudget);
    }

    // --- Fuzz: Refund Exactly Equals (Funded - Claimed) ---

    function testFuzz_RefundAlwaysMatchesUnallocated(
        uint256 reward,
        uint8 maxSubmissionsRaw,
        uint8 claimsCount
    ) public {
        reward = bound(reward, 1 ether, 20 ether);
        uint256 maxSubs = bound(maxSubmissionsRaw, 2, 8);
        claimsCount = uint8(bound(claimsCount, 0, maxSubs - 1)); // At least 1 reward left unclaimed

        bytes32 cId = keccak256(abi.encodePacked("fuzz-refund", reward, maxSubs, claimsCount));

        vm.prank(creator);
        escrow.createAndFundCampaign(cId, reward, maxSubs, 7 days, keccak256("meta"));

        // Execute partial claims
        for (uint256 i = 0; i < claimsCount; i++) {
            address contributor = address(uint160(0x2000 + i));
            bytes32 nonce = keccak256(abi.encodePacked("nonce-rf", i, cId));

            IDatasetEscrow.RewardAuthorization memory auth = IDatasetEscrow.RewardAuthorization({
                campaignId: cId,
                contributor: contributor,
                amount: reward,
                nonce: nonce,
                deadline: block.timestamp + 1 hours
            });
            bytes memory sig = _signAuthorization(auth, signerPrivateKey);

            vm.prank(contributor);
            escrow.claimReward(auth, sig);
        }

        // Creator cancels campaign
        vm.prank(creator);
        escrow.cancelCampaign(cId, "Fuzz cancel");

        // Warp past cooldown
        vm.warp(block.timestamp + 3 days + 1);

        uint256 totalFunded = reward * maxSubs;
        uint256 totalClaimed = reward * claimsCount;
        uint256 expectedRefund = totalFunded - totalClaimed;

        uint256 creatorBalanceBefore = token.balanceOf(creator);

        vm.prank(creator);
        uint256 refunded = escrow.refundUnallocatedFunds(cId);

        assertEq(refunded, expectedRefund);
        assertEq(token.balanceOf(creator), creatorBalanceBefore + expectedRefund);

        IDatasetEscrow.Campaign memory c = escrow.getCampaign(cId);
        assertEq(c.refundedAmount, expectedRefund);
        assertEq(c.claimedAmount + c.refundedAmount, c.fundedAmount);
    }
}
