# DataMint

**On-chain AI dataset marketplace powered by human contributors + instant Celo payouts.**

DataMint is a web-based dataset generation platform where companies create dataset requests, contributors submit real-world data (voice, image, text), AI validates submissions, and Celo smart contracts handle trustless escrow and payouts.

## Features

- **Dataset Creation:** AI builders can request specific data types (Voice, Image, Text).
- **On-Chain Escrow:** Rewards are locked in a Celo smart contract and released instantly upon approval.
- **Contributor Task Feed:** Mobile-friendly interface for contributors to find and complete tasks.
- **AI Validation Layer:** Instant quality and relevance checks.
- **MiniPay Integrated:** Seamless experience for Opera MiniPay users on Celo.

## Tech Stack

- **Frontend:** Next.js 15 (App Router), TailwindCSS, ShadCN UI
- **Backend:** Supabase (Auth, Database, Storage)
- **Blockchain:** Celo (Alfajores Testnet), Solidity, Ethers.js
- **AI:** OpenAI GPT-4o / Whisper (Planned for full integration)

## Getting Started

### Prerequisites

- Node.js 20+
- Supabase Project
- Celo Wallet (MiniPay/Metamask)

### Installation

1. Clone the repository
2. Install dependencies:
   ```bash
   npm install
   ```
3. Set up environment variables in `.env.local`:
   ```
   NEXT_PUBLIC_SUPABASE_URL=your_supabase_url
   NEXT_PUBLIC_SUPABASE_ANON_KEY=your_supabase_key
   NEXT_PUBLIC_ESCROW_ADDRESS=deployed_contract_address
   ```
4. Run the development server:
   ```bash
   $DEV_CMD
   ```

## Smart Contracts

The `DataMintEscrow.sol` contract is located in `contracts/contracts/`.

To run tests:
```bash
cd contracts && npx hardhat test
```

To deploy:
```bash
cd contracts && npx hardhat run scripts/deploy.ts --network alfajores
```

## License

MIT
