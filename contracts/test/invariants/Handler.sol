// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {DatasetEscrow} from "../../src/DatasetEscrow.sol";
import {IDatasetEscrow} from "../../src/interfaces/IDatasetEscrow.sol";
import {MockERC20} from "../mocks/MockERC20.sol";

contract EscrowHandler is Test {
    DatasetEscrow public escrow;
    MockERC20 public token;

    address public creator = address(0xC1);
    uint256 public signerPrivateKey = 0xA11CE;

    bytes32[] public activeCampaignIds;
    uint256 public totalGhostFunded;
    uint256 public totalGhostClaimed;
    uint256 public totalGhostRefunded;

    uint256 private nonceCounter;

    constructor(DatasetEscrow _escrow, MockERC20 _token) {
        escrow = _escrow;
        token = _token;

        token.mint(creator, type(uint128).max);
        vm.prank(creator);
        token.approve(address(escrow), type(uint256).max);
    }

    function createAndFund(
        uint256 rewardPerSubmission,
        uint8 maxSubmissions,
        uint32 duration
    ) public {
        rewardPerSubmission = bound(rewardPerSubmission, 1 ether, 10 ether);
        uint256 maxSubs = bound(maxSubmissions, 1, 5);
        duration = uint32(bound(duration, 1 hours, 30 days));

        bytes32 cId = keccak256(abi.encodePacked("inv-camp", activeCampaignIds.length, block.timestamp));

        vm.prank(creator);
        escrow.createAndFundCampaign(cId, rewardPerSubmission, maxSubs, duration, keccak256("inv-meta"));

        activeCampaignIds.push(cId);
        totalGhostFunded += (rewardPerSubmission * maxSubs);
    }

    function claim(uint256 campaignIndex, address contributor) public {
        if (activeCampaignIds.length == 0) return;
        if (contributor == address(0) || contributor == address(escrow)) {
            contributor = address(0x999);
        }

        bytes32 cId = activeCampaignIds[campaignIndex % activeCampaignIds.length];
        IDatasetEscrow.Campaign memory c = escrow.getCampaign(cId);

        if (c.state != IDatasetEscrow.CampaignState.ACTIVE) return;
        if (block.timestamp > c.claimDeadline) return;
        if (c.claimedCount >= c.maxSubmissions) return;

        bytes32 nonce = keccak256(abi.encodePacked("inv-nonce", nonceCounter++));
        uint256 deadline = block.timestamp + 1 hours;

        IDatasetEscrow.RewardAuthorization memory auth = IDatasetEscrow.RewardAuthorization({
            campaignId: cId,
            contributor: contributor,
            amount: c.rewardPerSubmission,
            nonce: nonce,
            deadline: deadline
        });

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
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPrivateKey, digest);
        bytes memory sig = abi.encodePacked(r, s, v);

        vm.prank(contributor);
        escrow.claimReward(auth, sig);

        totalGhostClaimed += c.rewardPerSubmission;
    }

    function cancelAndRefund(uint256 campaignIndex) public {
        if (activeCampaignIds.length == 0) return;

        bytes32 cId = activeCampaignIds[campaignIndex % activeCampaignIds.length];
        IDatasetEscrow.Campaign memory c = escrow.getCampaign(cId);

        if (c.state == IDatasetEscrow.CampaignState.ACTIVE) {
            vm.prank(creator);
            escrow.cancelCampaign(cId, "Invariant cancel");

            vm.warp(block.timestamp + 3 days + 1);

            uint256 refundable = escrow.getRefundableAmount(cId);
            if (refundable > 0) {
                vm.prank(creator);
                uint256 refunded = escrow.refundUnallocatedFunds(cId);
                totalGhostRefunded += refunded;
            }
        }
    }

    function getActiveCampaignsCount() external view returns (uint256) {
        return activeCampaignIds.length;
    }
}
