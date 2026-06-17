# DataMint (MVP PRD)

**Tagline:** On-chain AI dataset marketplace powered by human contributors + instant Celo payouts.

## 1. PRODUCT SUMMARY
DataMint is a web-based dataset generation platform where:
- Companies (or users) create dataset requests
- Contributors submit real-world data (voice, image, text)
- AI validates submissions
- Smart contracts on Celo escrow and release payments
- Final dataset is exported as a downloadable structured package

## 2. CORE PROBLEM
AI companies need high-quality datasets from real humans.
**Current issues:**
- Expensive data collection
- Slow payments to contributors
- Poor access to African/local data
- No transparency in validation or payout

## 3. MVP GOAL (Hackathon Scope)
Build a system that demonstrates: “Create dataset → contribute data → AI validates → blockchain pays → dataset is downloadable”

## 4. TARGET USERS
- **Dataset Creators:** AI builders, startups, researchers.
- **Contributors:** mobile users with MiniPay wallets, students, freelancers.

## 5. CORE FEATURES (MVP ONLY)
### 5.1 Dataset Creation (Client Side)
- Create dataset title
- Select type: Voice, Image, Text
- Define reward per submission
- Set number of submissions needed
- Fund escrow (Celo stablecoin via MiniPay)

### 5.2 Task Feed (Contributor Side)
- Browse available tasks
- Reward per task
- Task type
- Accept and submit data (audio/image/text)

### 5.3 AI Validation Layer (Simple logic)
- Voice: speech detected + clarity check
- Image: valid content + quality check
- Text: format/length + basic validation

### 5.4 Blockchain Layer (Celo Smart Contract)
- Escrow funding
- Task reward locking
- Payment release on approval
- Worker wallet payout (MiniPay compatible)

### 5.5 Dataset Export
- Structured dataset folder
- metadata.json or CSV
- Export Dataset button

## 6. TECH STACK
- **Frontend:** Next.js (App Router), TailwindCSS, ShadCN UI
- **Backend:** Supabase (Auth + DB + Storage)
- **AI Layer:** OpenAI API (GPT-4o / Whisper)
- **Blockchain:** Celo network, Solidity smart contract

## 7. DATABASE SCHEMA (SUPABASE)
- **users:** id, wallet_address, role (creator | contributor), reputation
- **datasets:** id, creator_id, title, type, reward_per_task, total_required, completed_count, status
- **submissions:** id, dataset_id, user_id, file_url, ai_score, status
- **payments:** id, submission_id, wallet_address, amount, tx_hash
