// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {DatasetEscrow} from "../../src/DatasetEscrow.sol";
import {IDatasetEscrow} from "../../src/interfaces/IDatasetEscrow.sol";
import {MockERC20} from "../mocks/MockERC20.sol";
import {EscrowHandler} from "./Handler.sol";

contract DatasetEscrowInvariantTest is Test {
    DatasetEscrow public escrow;
    MockERC20 public token;
    EscrowHandler public handler;

    address public admin = address(0xAD);
    uint256 public signerPrivateKey = 0xA11CE;
    address public platformSigner;

    function setUp() public {
        platformSigner = vm.addr(signerPrivateKey);
        token = new MockERC20("Celo Dollar", "cUSD");
        escrow = new DatasetEscrow(address(token), admin, platformSigner);

        handler = new EscrowHandler(escrow, token);

        targetContract(address(handler));
    }

    /**
     * @notice Invariant 1: Contract ERC20 balance must exactly equal (Total Funded - Total Claimed - Total Refunded).
     */
    function invariant_SolvencyAndBalanceConservation() public view {
        uint256 expectedBalance = handler.totalGhostFunded() - handler.totalGhostClaimed() - handler.totalGhostRefunded();
        assertEq(token.balanceOf(address(escrow)), expectedBalance);
    }

    /**
     * @notice Invariant 2: Total Claimed + Total Refunded can never exceed Total Funded.
     */
    function invariant_ClaimsAndRefundsNeverExceedFunded() public view {
        assertLe(handler.totalGhostClaimed() + handler.totalGhostRefunded(), handler.totalGhostFunded());
    }

    /**
     * @notice Invariant 3: For every tracked campaign, claimedAmount <= totalBudget and claimedCount <= maxSubmissions.
     */
    function invariant_PerCampaignCapacities() public view {
        uint256 count = handler.getActiveCampaignsCount();
        for (uint256 i = 0; i < count; i++) {
            bytes32 cId = handler.activeCampaignIds(i);
            IDatasetEscrow.Campaign memory c = escrow.getCampaign(cId);

            assertLe(c.claimedAmount, c.totalBudget);
            assertLe(c.claimedCount, c.maxSubmissions);
            assertLe(c.claimedAmount + c.refundedAmount, c.fundedAmount);
        }
    }
}
