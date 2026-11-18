# Phase 5: Flutter Mobile Application Architecture

## 1. Executive Summary

DataMint Phase 5 delivers a production-grade, multi-platform mobile application for Android and iOS using Flutter and Dart. DataMint connects dataset creators with contributors in a decentralized, AI-verified marketplace on the Celo blockchain.

A central engineering principle of Phase 5 is the **Unified Dual-Role Architecture**: rather than segmenting users into disjointed creator and contributor apps, a single authenticated session allows any user to fluidly toggle between **Contributor Mode** (task exploration, multi-modal data submission, real-time validation tracking, and on-chain reward claims) and **Creator Mode** (campaign creation wizard, escrow budget allocation, review queue management, and dataset quality oversight).

All business invariants, validation pipelines, and financial reconciliations remain anchored in the FastAPI backend and Celo smart contracts (`DatasetEscrow.sol`).

---

## 2. Architecture Overview

The mobile architecture adheres to clean, feature-driven domain boundaries with unidirectional reactive state management powered by Flutter Riverpod:

```
┌─────────────────────────────────────────────────────────────┐
│                       Flutter UI Layer                      │
│   (Material 3, Mint/Dark Slate Design Tokens, GoRouter)     │
└───────────────────────────────▲─────────────────────────────┘
                                │
┌───────────────────────────────┴─────────────────────────────┐
│                 Riverpod State Management                   │
│  (WorkspaceNotifier, CurrentUserNotifier, WalletNotifier)   │
└──────────────▲──────────────────────────────▲───────────────┘
               │                              │
┌──────────────┴──────────────┐┌──────────────┴───────────────┐
│     Backend Services        ││      Web3 Wallet Service     │
│ (Auth, Campaign, Submission)││ (Celo Alfajores, SIWE, cUSD) │
└──────────────▲──────────────┘└──────────────▲───────────────┘
               │                              │
┌──────────────┴──────────────┐┌──────────────┴───────────────┐
│        Dio ApiClient        ││          web3dart            │
│ (Bearer Auth, 401 Refresh)  ││ (JSON-RPC, ERC-20, Escrow)   │
└──────────────▲──────────────┘└──────────────▲───────────────┘
               │                              │
┌──────────────┴──────────────┐┌──────────────┴───────────────┐
│   FastAPI Modular Monolith  ││    Celo Smart Contracts      │
│  (Auth, Validation, Payout) ││    (DatasetEscrow, cUSD)     │
└─────────────────────────────┘└──────────────────────────────┘
```

---

## 3. Technology Choices & Rationale

- **Flutter 3.29.0 & Dart 3.7.0**: Single cross-platform codebase yielding native ARM performance on Android and iOS with 60/120fps hardware-accelerated rendering.
- **Flutter Riverpod (2.6.1)**: Compile-safe, declarative state management without reliance on `BuildContext`. Enables dependency injection and mock overrides in unit tests.
- **GoRouter (14.8.1)**: Declarative, deep-link aware router supporting authentication redirect guards.
- **Dio (5.11.1)**: Robust HTTP client providing interceptors for automatic Bearer token injection, synchronized 401 token refresh queue (preventing multiple simultaneous refreshes), and structured error translation.
- **web3dart (2.7.3)**: Native Dart implementation of Ethereum/Celo JSON-RPC protocols, personal message signing (`personal_sign` for SIWE), and ERC-20 contract calls.
- **flutter_secure_storage (9.2.4)**: Encrypted SharedPreferences on Android (MasterKey KeyStore) and Keychain on iOS for JWT tokens and sensitive wallet credentials.
- **image_picker, record, audioplayers**: Multi-modal media capture hardware integrations with in-memory streaming and preview capabilities.

---

## 4. Directory Structure

```text
mobile/
├── android/app/src/main/AndroidManifest.xml
├── assets/
│   ├── icons/
│   └── images/
├── lib/
│   ├── main.dart
│   ├── app/
│   │   ├── app.dart
│   │   ├── router.dart
│   │   └── theme/
│   │       └── app_theme.dart
│   ├── core/
│   │   ├── config/env_config.dart
│   │   ├── constants/app_constants.dart
│   │   ├── errors/app_exception.dart
│   │   ├── network/api_client.dart
│   │   ├── storage/secure_storage_service.dart
│   │   └── widgets/common_widgets.dart
│   ├── shared/
│   │   ├── models/models.dart
│   │   ├── providers/app_providers.dart
│   │   └── services/
│   │       ├── datamint_services.dart
│   │       └── wallet_service.dart
│   └── features/
│       ├── authentication/
│       ├── campaigns/
│       ├── home/
│       ├── marketplace/
│       ├── notifications/
│       ├── onboarding/
│       ├── profile/
│       ├── reviews/
│       ├── rewards/
│       └── submissions/
└── test/
    ├── api_client_test.dart
    ├── models_test.dart
    ├── wallet_service_test.dart
    └── widget_tests.dart
```

---

## 5. Authentication & Session Management

DataMint Mobile supports two authentication mechanisms:
1. **Email / Password**:
   - `POST /api/v1/auth/register` (supports dual `BOTH`, `CONTRIBUTOR`, or `CREATOR` role declaration).
   - `POST /api/v1/auth/login`.
2. **Sign-In with Ethereum (SIWE)**:
   - Contributor requests challenge nonce: `GET /api/v1/auth/siwe-challenge?address=0x...`
   - Mobile signs EIP-4361 message via connected Celo wallet.
   - Verified via `POST /api/v1/auth/siwe-verify` returning JWT keypair.

### Token Lifecycle & 401 Refresh Queue
- Tokens are stored in AES-encrypted storage via `SecureStorageService`.
- `ApiClient` interceptor intercepts `401 Unauthorized` responses on authenticated endpoints.
- If multiple concurrent requests receive 401s, an internal `Completer<String?>` queues requests so that only one `/auth/refresh` call is made. Once refreshed, all pending requests are re-executed with the new bearer token.
- If refresh fails, session is cleared and GoRouter redirects the user to `/login`.

---

## 6. Wallet Integration & Celo Architecture

- **Target Networks**: Celo Alfajores Testnet (Chain ID `44787`) and Celo Mainnet (Chain ID `42220`).
- **Currency & Escrow**: Native gas token **CELO** and stable payment currency **cUSD** (`0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1`).
- **MiniPay Detection**: User agent and injected Web3 provider checks enable zero-friction sign-in for Opera MiniPay mobile browser users.
- **Non-Custodial Architecture**: Mobile never retains raw private keys; signatures are performed via wallet IPC / deep links or ephemeral development credentials in test mode.

---

## 7. Contributor Workflows

1. **Marketplace Discovery**: Filter campaigns by modality (`TEXT`, `VOICE`, `IMAGE`), search by keywords, view verified escrow funding badges and reward rates.
2. **Instruction Inspection**: Review campaign instructions, format restrictions, and AI validation criteria before beginning submission.
3. **Multi-Modal Data Capture**:
   - **Text**: Draft editor with live character counting.
   - **Voice**: Microphone capture with recording duration constraints, timer, and preview audio playback.
   - **Image**: Camera/gallery selection with dimension checks.
4. **Three-Phase Direct Upload Pipeline**:
   - Create draft session: `POST /api/v1/submissions/drafts`
   - Request presigned S3/MinIO upload URL: `POST /api/v1/submissions/drafts/{id}/upload-url`
   - Direct binary upload to object storage with upload progress tracking.
   - Confirmation: `POST /api/v1/submissions/drafts/{id}/confirm-upload`
   - Transition to validation: `POST /api/v1/submissions/drafts/{id}/submit`
5. **Timeline & Findings Tracking**: Contributor monitors submission status through `PENDING_VALIDATION`, `APPROVED`, `HUMAN_REVIEW`, or `REJECTED`.
6. **Contributor Appeals**: When rejected, contributor can launch the appeal dialog to provide counter-evidence for manual re-evaluation.

---

## 8. Creator Workflows

1. **Campaign Creation Wizard**:
   - Step 1: Basics (Title, description, category, modality).
   - Step 2: Rules (Contributor instructions, minimum acceptance score).
   - Step 3: Budget & Escrow (cUSD reward per item, target count, total escrow deposit calculation).
2. **Campaign Lifecycle**: Manage draft campaigns and publish directly to the marketplace (`POST /api/v1/campaigns/drafts/{id}/publish`).
3. **Review Queue**: Review submissions flagged by the AI validation pipeline.
4. **Manual Intervention**: Approve or reject submissions with structured reviewer feedback.

---

## 9. AI Validation & Review Experience

Submissions display granular audit findings from Phase 4 pipelines:
- Format verification (decodability, dimensions, audio duration).
- AI quality scoring (semantic relevance, instruction adherence).
- Deduplication and spam check results.
- Confidence score (%) with severity badges (Info, Warning, Error).

---

## 10. Financial Orchestration & Payout Claims

1. Once a submission is `APPROVED`, it enters the `Ready to Claim` state in the Rewards tab.
2. Contributor taps **Claim**.
3. App fetches EIP-712 typed voucher from backend:
   ```json
   {
     "campaign_id": "0x...",
     "contributor": "0x...",
     "amount": "2500000000000000000",
     "nonce": 1,
     "deadline": 1800000000,
     "signature": "0x...",
     "contract_address": "0x322813Fd9A801c5507c9de605d63CEA4f2CE6c44",
     "chain_id": 44787
   }
   ```
4. Contributor wallet broadcasts `DatasetEscrow.claimReward(...)` transaction on Celo.
5. Transaction hash is confirmed via `POST /api/v1/payouts/submissions/{id}/claim`.
6. Wallet balances update in real time.

---

## 11. State Management Implementation

- **Unidirectional Data Flow**: State is isolated in Riverpod StateNotifiers (`CurrentUserNotifier`, `WorkspaceNotifier`, `WalletStateNotifier`).
- **Optimistic Updates**: Submissions and campaigns invalidate their cached FutureProviders (`ref.invalidate(...)`) upon mutations, ensuring immediate UI reactivity.
- **Separation of Concerns**: UI widgets do not perform direct network requests or storage operations; they delegate entirely to domain services.

---

## 12. Design System & Component Architecture

- **Color Palette**: Mint primary (`#10B981`), Mint light (`#34D399`), Dark Slate background (`#0B0F19`), Surface (`#111827`), Card (`#1F2937`), Border (`#374151`), Celo Gold (`#F59E0B`).
- **Typography & Accessibility**: High contrast ratios compliant with WCAG AAA standards.
- **Shared Components**:
  - `DataMintButton`: Standardized primary and outlined buttons with integrated loading spinner.
  - `StatusBadge`: Material 3 pill badges with semantic color coding for all submission states.
  - `ModalityBadge`: Visual modality chips with icons for Text, Voice, and Image.
  - `EmptyStateView`: Illustrated placeholders with clear call-to-action buttons.

---

## 13. Security Considerations

- **Secure Storage**: Tokens and sensitive keys stored in encrypted hardware keystores.
- **Non-Custodial Keys**: Contributor private keys are never stored on disk or transmitted to the backend.
- **Presigned Uploads**: Media files stream directly from the device to private object storage via single-use, time-limited presigned PUT URLs, avoiding memory exhaustion on the application server.
- **Deep Link Sanitization**: Deep links for SIWE and WalletConnect validate origin schemes to prevent intent interception.

---

## 14. Testing Strategy & Results

All test suites execute via `flutter test`:
1. `models_test.dart`: Serialization of users, campaigns, submissions, validation findings, and payout vouchers (5 passed).
2. `api_client_test.dart`: Header injection, 401 refresh interceptors, error formatting (3 passed).
3. `wallet_service_test.dart`: Celo wallet connection, SIWE personal message signing, disconnect lifecycle (4 passed).
4. `widget_tests.dart`: Common button states, status badges, modality badges, workspace toggle, form validation (6 passed).

**Total Test Results**: 18 unit and widget tests passing with 0 failures and 0 warnings.
**Static Analysis**: `flutter analyze` passes with zero issues.

---

## 15. Incomplete Items & Gaps

- **Production Push Notifications**: FCM (Firebase Cloud Messaging) / APNs configuration requires registered Google Services JSON and Apple Provisioning Profiles, currently stubbed via in-app polling (`NotificationService`).
- **WalletConnect v2 Relay Infrastructure**: Direct Web3 RPC and MiniPay are fully active; external WalletConnect modal pairing requires a project ID configured in production environment variables.

---

## 16. Production Readiness Assessment

DataMint Mobile is structurally complete, strictly aligned with backend API contracts, and verified through automated tests and static analysis. It provides a cohesive, premium experience for decentralized AI data collection.

---

## 17. Verification Instructions

1. **Static Analysis**:
   ```bash
   export PATH="/home/codegallantx/development/flutter/bin:$PATH"
   cd mobile && flutter analyze
   ```
2. **Automated Test Suite**:
   ```bash
   export PATH="/home/codegallantx/development/flutter/bin:$PATH"
   cd mobile && flutter test
   ```
