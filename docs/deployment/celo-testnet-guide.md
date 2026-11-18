# Celo Testnet Deployment & Local Testing Guide

This guide details the procedure for testing, deploying, and verifying `DatasetEscrow.sol` on local Anvil networks and the Celo Sepolia testnet.

---

## 1. Local Testing with Foundry

Run the complete test suite locally:

```bash
# Navigate to contracts directory
cd contracts

# Run all unit tests
forge test --match-contract DatasetEscrowUnitTest -vv

# Run fuzz tests (randomized parameter verification)
forge test --match-contract DatasetEscrowFuzzTest -vv

# Run stateful invariant tests (128,000+ continuous calls)
forge test --match-contract DatasetEscrowInvariantTest -vv

# Check test gas snapshots
forge snapshot
```

---

## 2. Local Anvil Deployment

Start a local development node and broadcast the deployment:

```bash
# Terminal 1: Start Anvil
anvil

# Terminal 2: Deploy to local Anvil
cd contracts
forge script script/DeployDatasetEscrow.s.sol:DeployDatasetEscrowScript \
  --rpc-url http://127.0.0.1:8545 \
  --broadcast
```

*Note: On local chain ID 31337, the script automatically deploys a `MockERC20` token with 18 decimals and configures it as the cUSD token.*

---

## 3. Celo Sepolia Testnet Deployment

### 3.1 Environment Setup
1. Copy the environment template:
   ```bash
   cp contracts/.env.example contracts/.env
   ```
2. Populate the required environment variables:
   ```ini
   PRIVATE_KEY=<YOUR_TESTNET_PRIVATE_KEY_WITHOUT_0x>
   DEFAULT_ADMIN_ADDRESS=<YOUR_ADMIN_WALLET_ADDRESS>
   PLATFORM_SIGNER_ADDRESS=<YOUR_PLATFORM_VOUCHER_SIGNER_ADDRESS>
   CUSD_TOKEN_ADDRESS=0x2F25deB3848C207fc8E0c34035B3Ba7fC157602B
   CELO_SEPOLIA_RPC=https://forno.celo-sepolia.celo-testnet.org
   CELOSCAN_API_KEY=<OPTIONAL_FOR_VERIFICATION>
   ```

### 3.2 Fund Deployer Wallet
Acquire Celo Sepolia testnet tokens (CELO and cUSD) from the official Celo testnet faucet:
- Faucet: [https://faucet.celo.org/celo-sepolia](https://faucet.celo.org/celo-sepolia)

### 3.3 Dry-Run Simulation
Simulate the deployment transaction against the Celo Sepolia RPC without spending gas:
```bash
cd contracts
forge script script/DeployDatasetEscrow.s.sol:DeployDatasetEscrowScript \
  --rpc-url https://forno.celo-sepolia.celo-testnet.org
```

### 3.4 Live Broadcast & Verification
Broadcast the transaction to the Celo Sepolia network:
```bash
forge script script/DeployDatasetEscrow.s.sol:DeployDatasetEscrowScript \
  --rpc-url https://forno.celo-sepolia.celo-testnet.org \
  --broadcast \
  --verify \
  --verifier-url https://api-sepolia.celoscan.io/api
```

---

## 4. Post-Deployment Verification Checklist

Once deployed to testnet:

1. **Verify Role Assignment:**
   ```bash
   # Check admin role
   cast call <ESCROW_ADDRESS> "hasRole(bytes32,address)(bool)" \
     0x0000000000000000000000000000000000000000000000000000000000000000 \
     <DEFAULT_ADMIN_ADDRESS> \
     --rpc-url https://forno.celo-sepolia.celo-testnet.org

   # Check signer role
   cast call <ESCROW_ADDRESS> "hasRole(bytes32,address)(bool)" \
     $(cast keccak "SIGNER_ROLE") \
     <PLATFORM_SIGNER_ADDRESS> \
     --rpc-url https://forno.celo-sepolia.celo-testnet.org
   ```

2. **Verify cUSD Token Binding:**
   ```bash
   cast call <ESCROW_ADDRESS> "cusdToken()(address)" \
     --rpc-url https://forno.celo-sepolia.celo-testnet.org
   ```

3. **Verify EIP-712 Domain Separator:**
   Verify that `name == "DataMint DatasetEscrow"` and `version == "1"`.
