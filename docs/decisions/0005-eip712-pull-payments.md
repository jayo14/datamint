# ADR 0005: EIP-712 Cryptographic Pull-Payments

## Status
Accepted

## Context
Push-payments (where the platform backend broadcasts a transaction and pays gas to send cUSD to contributors) expose the platform to gas price spikes, stuck nonces, high operational costs, and single-point-of-failure hot wallet balance risks.

## Decision
We implement a **pull-payment architecture using EIP-712 cryptographic vouchers**:
1. When a submission is approved, the platform backend signs an EIP-712 structured data voucher authorizing the contributor's wallet to withdraw the designated reward from the campaign escrow.
2. The contributor submits the voucher to `DataMintEscrow.sol` via their client wallet (e.g. MiniPay, Valora, MetaMask).
3. The smart contract validates the platform signature, checks the voucher nonce against double-spending, and transfers cUSD directly to the contributor.
4. The contributor pays the minimal Celo network gas fee, or uses paymaster sponsorship if enabled.

## Consequences
- **Positive:** Backend never holds custodial payout funds; zero hot-wallet balance exhaustion risks; immune to stuck server transaction nonces.
- **Negative:** Contributor must execute a contract interaction to withdraw funds.
