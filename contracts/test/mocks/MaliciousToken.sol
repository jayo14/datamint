// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IDatasetEscrow} from "../../src/interfaces/IDatasetEscrow.sol";

/**
 * @title MaliciousToken
 * @notice ERC20 token designed to test reentrancy and transfer failures.
 */
contract MaliciousToken is ERC20 {
    bool public shouldFailTransfers;
    bool public shouldAttemptReentrancy;
    address public targetEscrow;
    IDatasetEscrow.RewardAuthorization public targetAuth;
    bytes public targetSignature;

    constructor() ERC20("Malicious cUSD", "mcUSD") {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    function setFailTransfers(bool fail) external {
        shouldFailTransfers = fail;
    }

    function setReentrancyConfig(
        address escrow,
        IDatasetEscrow.RewardAuthorization calldata auth,
        bytes calldata sig
    ) external {
        shouldAttemptReentrancy = true;
        targetEscrow = escrow;
        targetAuth = auth;
        targetSignature = sig;
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        if (shouldFailTransfers) {
            return false;
        }
        if (shouldAttemptReentrancy && targetEscrow != address(0)) {
            shouldAttemptReentrancy = false; // prevent infinite loop
            IDatasetEscrow(targetEscrow).claimReward(targetAuth, targetSignature);
        }
        return super.transfer(to, amount);
    }

    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        if (shouldFailTransfers) {
            return false;
        }
        return super.transferFrom(from, to, amount);
    }
}
