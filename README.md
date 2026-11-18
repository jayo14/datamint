# DataMint

[![Backend CI](https://github.com/datamint/datamint/actions/workflows/backend-ci.yml/badge.svg)](https://github.com/datamint/datamint/actions/workflows/backend-ci.yml)
[![Contracts CI](https://github.com/datamint/datamint/actions/workflows/contracts-ci.yml/badge.svg)](https://github.com/datamint/datamint/actions/workflows/contracts-ci.yml)
[![Web CI](https://github.com/datamint/datamint/actions/workflows/web-ci.yml/badge.svg)](https://github.com/datamint/datamint/actions/workflows/web-ci.yml)
[![Mobile CI](https://github.com/datamint/datamint/actions/workflows/mobile-ci.yml/badge.svg)](https://github.com/datamint/datamint/actions/workflows/mobile-ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

> **Decentralized AI dataset marketplace powered by human contributors, multi-modal automated validation, and instant cUSD micro-payouts on Celo.**

---

## 1. Overview

DataMint connects AI developers needing domain-specific training data with global contributors. Contributors capture and upload multi-modal datasets (text, speech/voice, images), automated provider-agnostic AI validation pipelines verify submission quality, human reviewers adjudicate edge cases, and on-chain escrow contracts issue cryptographic EIP-712 reward vouchers redeemable instantly for cUSD on the Celo network.

### Core Architectural Invariants:
- **Non-Custodial Escrow:** Funds remain secured on-chain in `DatasetEscrow.sol`. Platform signer keys authorize withdrawals via cryptographic vouchers without holding custody.
- **Double-Entry Financial Accounting:** Every token transition is journaled in an immutable ledger enforcing:
  $$\text{Funded} = \text{Available} + \text{Reserved} + \text{Claimed} + \text{Refunded}$$
- **Dual-Capability Identity:** Contributors and Creators operate seamlessly from a single unified identity on both web and mobile.

---

## 2. Interactive API Documentation (`/docs`)

All backend API endpoints are strictly documented with OpenAPI 3.1 / Swagger UI specifications. 

When running the backend server locally or in production, navigate to:
- **Interactive Swagger UI:** [http://localhost:8000/docs](http://localhost:8000/docs)
- **ReDoc Documentation:** [http://localhost:8000/redoc](http://localhost:8000/redoc)
- **OpenAPI JSON Schema:** [http://localhost:8000/openapi.json](http://localhost:8000/openapi.json)

---

## 3. Complete API Endpoint Reference

All domain endpoints are versioned under `/api/v1`:

### 3.1 Authentication & Wallet Identity (`/api/v1/auth`)
| Method | Endpoint | Description | Access |
| :--- | :--- | :--- | :--- |
| `POST` | `/api/v1/auth/nonce` | Generate EIP-4361 SIWE challenge nonce for wallet address | Public |
| `GET` | `/api/v1/auth/siwe-challenge` | Alias GET endpoint generating SIWE nonce for client convenience | Public |
| `POST` | `/api/v1/auth/verify` | Verify signed EIP-4361 message and issue JWT access/refresh tokens | Public |
| `POST` | `/api/v1/auth/siwe-verify` | Alias POST endpoint for SIWE verification | Public |
| `POST` | `/api/v1/auth/register` | Register new user via email and password | Public |
| `POST` | `/api/v1/auth/login` | Authenticate existing user via email and password | Public |
| `POST` | `/api/v1/auth/refresh` | Rotate and issue fresh access token using valid refresh token | Public |
| `POST` | `/api/v1/auth/logout` | Revoke session and blacklist refresh token | Authenticated |

### 3.2 User Profile & Capabilities (`/api/v1/users`)
| Method | Endpoint | Description | Access |
| :--- | :--- | :--- | :--- |
| `GET` | `/api/v1/users/me` | Fetch authenticated user profile, active capabilities, and reputation | Authenticated |
| `PUT` | `/api/v1/users/me/profile` | Update profile attributes (display name, avatar, bio) | Authenticated |

### 3.3 Multi-Chain Wallets (`/api/v1/wallets`)
| Method | Endpoint | Description | Access |
| :--- | :--- | :--- | :--- |
| `GET` | `/api/v1/wallets/` | List all linked wallet addresses for authenticated user | Authenticated |
| `POST` | `/api/v1/wallets/challenge` | Generate linking challenge nonce for new secondary wallet | Authenticated |
| `POST` | `/api/v1/wallets/link` | Verify signature and link new wallet address to user account | Authenticated |
| `PUT` | `/api/v1/wallets/{address}/primary` | Designate target address as primary payout destination | Authenticated |
| `DELETE`| `/api/v1/wallets/{address}` | Unlink secondary wallet from account | Authenticated |

### 3.4 Marketplace Discovery (`/api/v1/marketplace`)
| Method | Endpoint | Description | Access |
| :--- | :--- | :--- | :--- |
| `GET` | `/api/v1/marketplace/tasks` | Browse active dataset campaigns with filters (type, reward, category) | Public |
| `GET` | `/api/v1/marketplace` | Alias route for public marketplace browsing | Public |
| `GET` | `/api/v1/marketplace/{id}` | Retrieve specific campaign public details and submission criteria | Public |

### 3.5 Dataset Campaigns (`/api/v1/campaigns`)
| Method | Endpoint | Description | Access |
| :--- | :--- | :--- | :--- |
| `POST` | `/api/v1/campaigns/` | Create a new dataset bounty campaign in `DRAFT` state | Creator |
| `GET` | `/api/v1/campaigns/my-campaigns` | List campaigns created by authenticated creator | Creator |
| `GET` | `/api/v1/campaigns/{id}` | Get detailed campaign parameters, progress, and escrow status | Creator / Public |
| `PUT` | `/api/v1/campaigns/{id}` | Modify editable draft parameters before on-chain funding | Creator |
| `POST` | `/api/v1/campaigns/{id}/submit-funding` | Transition to `PENDING_FUNDING` and get on-chain escrow parameters | Creator |

### 3.6 Submissions & Asset Lifecycle (`/api/v1/submissions`)
| Method | Endpoint | Description | Access |
| :--- | :--- | :--- | :--- |
| `POST` | `/api/v1/submissions/drafts` | Initialize a new submission draft for target campaign | Contributor |
| `PUT` | `/api/v1/submissions/drafts/{id}` | Update draft text payload or contributor metadata | Contributor |
| `POST` | `/api/v1/submissions/drafts/{id}/upload-url` | Generate secure presigned S3 upload URL for media asset | Contributor |
| `POST` | `/api/v1/submissions/drafts/{id}/confirm-upload` | Confirm asset was transferred to private storage bucket | Contributor |
| `POST` | `/api/v1/submissions/drafts/{id}/submit` | Atomically reserve campaign capacity and queue for AI validation | Contributor |
| `GET` | `/api/v1/submissions/my-submissions` | List all submissions authored by authenticated contributor | Contributor |
| `GET` | `/api/v1/submissions/campaigns/{id}` | List all submissions received for creator's campaign | Creator |
| `GET` | `/api/v1/submissions/{id}` | Get submission details, asset metadata, and AI validation findings | Author / Creator / Reviewer |

### 3.7 Media & Private Storage (`/api/v1/media`)
| Method | Endpoint | Description | Access |
| :--- | :--- | :--- | :--- |
| `GET` | `/api/v1/media/submissions/{id}/assets/{asset_id}/download-url` | Generate short-lived presigned download URL for private asset | Authorized Only |

### 3.8 Human Review & Reviewer Queue (`/api/v1/reviews`)
| Method | Endpoint | Description | Access |
| :--- | :--- | :--- | :--- |
| `GET` | `/api/v1/reviews/queue` | Paginated queue of submissions requiring manual adjudication | Reviewer |
| `GET` | `/api/v1/reviews/submissions/{id}` | Fetch full submission context and validation findings for review | Reviewer |
| `POST` | `/api/v1/reviews/submissions/{id}/decide` | Submit human review decision (`APPROVED` or `REJECTED`) | Reviewer |

### 3.9 Appeals Subsystem (`/api/v1/appeals`)
| Method | Endpoint | Description | Access |
| :--- | :--- | :--- | :--- |
| `POST` | `/api/v1/appeals/submissions/{id}` | Submit an appeal on a rejected submission with evidence | Contributor |
| `GET` | `/api/v1/appeals/submissions/{id}` | Get status and decision notes for submitted appeal | Contributor / Reviewer |
| `POST` | `/api/v1/appeals/{id}/resolve` | Adjudicate appeal (`UPHELD` or `OVERTURNED`) | Reviewer |

### 3.10 Payout Vouchers & Payments (`/api/v1/payouts`, `/api/v1/payments`)
| Method | Endpoint | Description | Access |
| :--- | :--- | :--- | :--- |
| `GET` | `/api/v1/payouts/submissions/{id}/voucher` | Fetch cryptographic EIP-712 reward voucher for approved submission | Contributor |
| `POST` | `/api/v1/payouts/submissions/{id}/claim` | Record on-chain voucher claim transaction hash | Contributor |
| `GET` | `/api/v1/payments/ledger/{campaign_id}` | Chronological double-entry journal entries for campaign | Creator / Admin |
| `GET` | `/api/v1/payments/vouchers` | List all reward vouchers issued to authenticated user | Contributor |

### 3.11 Financial Reconciliation & Auditing (`/api/v1/reconciliation`)
| Method | Endpoint | Description | Access |
| :--- | :--- | :--- | :--- |
| `GET` | `/api/v1/reconciliation/campaigns` | Audit all campaign escrow accounts against ledger math | Admin |
| `GET` | `/api/v1/reconciliation/campaigns/{id}` | Deep audit single campaign escrow against smart contract state | Admin |
| `POST` | `/api/v1/reconciliation/sync-blockchain` | Trigger manual catch-up event indexing from RPC node | Admin |

### 3.12 Notifications (`/api/v1/notifications`)
| Method | Endpoint | Description | Access |
| :--- | :--- | :--- | :--- |
| `GET` | `/api/v1/notifications` | Paginated in-app notifications feed for authenticated user | Authenticated |
| `PUT` | `/api/v1/notifications/{id}/read` | Mark specific notification as read | Authenticated |

### 3.13 System Health & Diagnostics (`/api/v1/health`)
| Method | Endpoint | Description | Access |
| :--- | :--- | :--- | :--- |
| `GET` | `/api/v1/health/healthz` | High-frequency liveness probe | Public |
| `GET` | `/api/v1/health/readyz` | Deep readiness probe verifying PostgreSQL and Redis connectivity | Public |

---

## 4. Platform Architecture

```
                             +------------------------+
                             |   Next.js 16 Web App   |
                             |   Flutter Mobile App   |
                             +-----------+------------+
                                         |  /api/v1
                                         v
                         +-------------------------------+
                         |   DataMint FastAPI Backend    |
                         |  (Modular Monolith on :8000)  |
                         +---------------+---------------+
                                         |
         +-----------------------+-------+-----------------------+
         |                       |                               |
         v                       v                               v
+------------------+   +-------------------+           +-------------------+
|  PostgreSQL 16   |   |   Redis 7 Cache   |           | Private S3 Bucket |
|  Async SQLAlchemy|   |   & Celery Broker |           | (Presigned URLs)  |
+------------------+   +---------+---------+           +-------------------+
                                 |
                                 v
                     +-----------------------+
                     | Celery Worker & Beat  |
                     |  - Multi-modal AI Val |
                     |  - Celo Event Indexer |
                     |  - Ledger Reconciler  |
                     +-----------+-----------+
                                 |
                                 v  EIP-712 Vouchers
                     +-----------------------+
                     | Celo Blockchain (cUSD)|
                     |   DatasetEscrow.sol   |
                     +-----------------------+
```

---

## 5. Getting Started

### 5.1 Prerequisites
- Python 3.12+ (managed with `uv`)
- Node.js 20+ & npm
- Flutter 3.29.0+ & Dart 3.7.0+
- PostgreSQL 16+ & Redis 7+
- Foundry (`forge`) & Hardhat

### 5.2 Backend API & Workers Setup

```bash
cd backend

# Create virtual environment and install dependencies
uv venv
source .venv/bin/activate
uv pip install -e ".[dev]"

# Configure environment variables
cp .env.example .env

# Apply database migrations
alembic upgrade head

# Start API server (serves OpenAPI docs at http://localhost:8000/docs)
uvicorn app.main:app --reload --port 8000

# In a separate terminal: Start Celery worker
celery -A app.workers.celery_app worker --loglevel=info --concurrency=4

# In a separate terminal: Start Celery beat scheduler
celery -A app.workers.celery_app beat --loglevel=info
```

### 5.3 Web Frontend Setup (Next.js)

```bash
# In repository root
npm install

# Start Next.js development server
npm run dev
# Web application available at http://localhost:3000
```

### 5.4 Mobile Application Setup (Flutter Android & iOS)

```bash
cd mobile

# Install Flutter dependencies
flutter pub get

# Run static analysis
flutter analyze

# Run unit and widget tests
flutter test

# Run application on connected device or emulator
flutter run
```

### 5.5 Smart Contracts Setup

```bash
cd contracts

# Run Hardhat integration tests
npx hardhat test

# Run Foundry unit and fuzz tests
forge test
```

### 5.6 Production Docker Orchestration

Run the entire hardened stack (PostgreSQL, Redis, FastAPI Backend, Celery Worker, Celery Beat) in isolated networks with resource limits:

```bash
docker-compose -f docker-compose.prod.yml up --build -d
```

---

## 6. Testing & Quality Verification

Run all test suites across the repository:

```bash
# 1. Backend test suite (47 tests passing)
backend/.venv/bin/pytest backend/tests -v

# 2. Smart contracts test suite (4 tests passing)
cd contracts && npx hardhat test

# 3. Web frontend linting and compilation (0 errors, 0 warnings)
npm run lint && npm run build

# 4. Mobile application analysis and tests (0 issues, 13 tests passing)
cd mobile && flutter analyze && flutter test

# 5. Automated Disaster Recovery Drill
./scripts/backup_restore_test.sh

# 6. Asynchronous Load Benchmark
./scripts/load_test.py --concurrency 25 --duration 10
```

---

## 7. License

This project is licensed under the [MIT License](LICENSE).
