// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {DatasetEscrow} from "../src/DatasetEscrow.sol";
import {MockERC20} from "../test/mocks/MockERC20.sol";

/**
 * @title DeployDatasetEscrowScript
 * @notice Deterministic deployment script for DatasetEscrow on local anvil, Celo Sepolia testnet, or Celo mainnet.
 */
contract DeployDatasetEscrowScript is Script {
    // Official Celo Mainnet cUSD address (Chain ID: 42220)
    address public constant CELO_MAINNET_CUSD = 0x765DE816845861e75A25fCA122bb6898B8B1282a;

    function run() external returns (address escrowAddress, address tokenAddress) {
        uint256 deployerPrivateKey = vm.envOr("PRIVATE_KEY", uint256(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80));
        address admin = vm.envOr("DEFAULT_ADMIN_ADDRESS", vm.addr(deployerPrivateKey));
        address platformSigner = vm.envOr("PLATFORM_SIGNER_ADDRESS", vm.addr(deployerPrivateKey));

        address cusd = vm.envOr("CUSD_TOKEN_ADDRESS", address(0));

        vm.startBroadcast(deployerPrivateKey);

        // If local chain (31337) and no cUSD provided, deploy mock cUSD
        if (block.chainid == 31337 && cusd == address(0)) {
            console.log("Local chain detected: Deploying MockERC20 cUSD...");
            MockERC20 mockCusd = new MockERC20("Celo Dollar Mock", "cUSD");
            cusd = address(mockCusd);
            console.log("Mock cUSD deployed at:", cusd);
        } else if (cusd == address(0)) {
            // Default to Celo Mainnet if chainid matches
            if (block.chainid == 42220) {
                cusd = CELO_MAINNET_CUSD;
            } else {
                revert("CUSD_TOKEN_ADDRESS must be provided for non-local deployment");
            }
        }

        console.log("Deploying DatasetEscrow...");
        console.log("  Token:         ", cusd);
        console.log("  Admin:         ", admin);
        console.log("  PlatformSigner:", platformSigner);
        console.log("  Chain ID:      ", block.chainid);

        DatasetEscrow escrow = new DatasetEscrow(cusd, admin, platformSigner);
        escrowAddress = address(escrow);
        tokenAddress = cusd;

        console.log("DatasetEscrow deployed successfully at:", escrowAddress);

        vm.stopBroadcast();
    }
}
