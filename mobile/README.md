# DataMint Mobile Application (Flutter)

DataMint Mobile is the production-grade Flutter application for Android and iOS that connects dataset creators with contributors in a decentralized, AI-verified marketplace on the Celo blockchain.

The application allows a single authenticated user to operate seamlessly across both **Contributor** and **Creator** workspaces.

---

## Key Features

- **Unified Dual-Role Experience**: Single codebase supporting Contributor (task discovery, multi-modal submissions, earnings claims) and Creator (campaign publishing, escrow funding, review queue management) with an instant workspace toggle.
- **Authentication**: JWT authentication with automatic 401 token refresh queue, plus native **Sign-In with Ethereum (SIWE)** on Celo.
- **Multi-Modal Data Capture**:
  - **Text**: In-app rich text entry with character counting and real-time instruction adherence checks.
  - **Audio/Voice**: Integrated microphone recorder with recording timers, playback preview, and re-recording controls.
  - **Image**: Camera capture and photo gallery picker with dimension validation and size checks.
  - **Direct-to-Cloud Upload Pipeline**: Secure 3-step presigned S3/MinIO upload pipeline (`upload-url` $\to$ binary streaming PUT $\to$ `confirm-upload` $\to$ `submit`).
- **Real-Time AI Validation Tracking**: Transparent finding badges (Pass, Warning, Fail), confidence scores, and one-tap Contributor Appeal submissions.
- **Human Review Queue**: Reviewer decision dialog for escalated submissions (`Approve` / `Reject` with feedback notes).
- **On-Chain Financial Settlement**:
  - Direct integration with Celo Alfajores Testnet (44787) and Celo Mainnet (42220).
  - MiniPay detection and Web3 wallet signing.
  - Real-time balance queries for native **CELO** and **cUSD** ERC-20 tokens.
  - EIP-712 typed payout vouchers verified and settled on `DatasetEscrow.sol`.
- **In-App Notification Center**: Real-time event notifications with unread badges and mark-as-read tracking.

---

## Technology Stack

| Layer | Technology |
|---|---|
| Framework | Flutter 3.29.0 (Dart 3.7.0) |
| State Management | Flutter Riverpod (2.6.1) |
| Routing | GoRouter (14.8.1) with auth redirect guards |
| HTTP & Network | Dio (5.11.1) with retry interceptors |
| Web3 & Crypto | web3dart (2.7.3), crypto (3.0.8) |
| Secure Storage | flutter_secure_storage (9.2.4) |
| Media Capture | image_picker, record, audioplayers |
| Design System | Material 3 with DataMint Mint (`#10B981`) and Dark Slate (`#0B0F19`) |

---

## Directory Structure

```text
mobile/
├── android/
│   └── app/src/main/AndroidManifest.xml   # Android permissions and deep links
├── assets/
│   ├── icons/
│   └── images/
├── lib/
│   ├── main.dart                          # Application entry point
│   ├── app/
│   │   ├── app.dart                       # MaterialApp.router configuration
│   │   ├── router.dart                    # GoRouter with authentication redirect guards
│   │   └── theme/
│   │       └── app_theme.dart             # Material 3 light & dark design system
│   ├── core/
│   │   ├── config/
│   │   │   └── env_config.dart            # Environment & Celo RPC configuration
│   │   ├── constants/
│   │   │   └── app_constants.dart         # Modalities, keys, limits, and timeouts
│   │   ├── errors/
│   │   │   └── app_exception.dart         # Typed domain exceptions
│   │   ├── network/
│   │   │   └── api_client.dart            # Dio client with 401 token refresh queue
│   │   ├── storage/
│   │   │   └── secure_storage_service.dart # Encrypted secure storage wrapper
│   │   └── widgets/
│   │       └── common_widgets.dart        # Reusable buttons, badges, empty states
│   ├── shared/
│   │   ├── models/
│   │   │   └── models.dart                # User, Campaign, Submission, Finding, Voucher
│   │   ├── providers/
│   │   │   └── app_providers.dart         # Riverpod global states and notifiers
│   │   └── services/
│   │       ├── datamint_services.dart     # Auth, Marketplace, Submission, Review APIs
│   │       └── wallet_service.dart        # Web3 Celo connectivity & message signing
│   └── features/
│       ├── authentication/                # Login, Register, SIWE screens
│       ├── campaigns/                   # Wizard creation & creator campaigns
│       ├── home/                          # Workspace scaffold & role toggle
│       ├── marketplace/                   # Task discovery & campaign detail
│       ├── notifications/                 # In-app notification center
│       ├── onboarding/                    # Welcome carousel & value props
│       ├── profile/                       # User profile, wallet linking, logout
│       ├── reviews/                       # Human review queue & decision dialogs
│       ├── rewards/                       # cUSD balance & on-chain claim tracking
│       └── submissions/                   # Multi-modal editor & status timeline
└── test/
    ├── api_client_test.dart               # Network interceptor & error tests
    ├── models_test.dart                   # JSON deserialization & capability tests
    ├── wallet_service_test.dart           # Celo Web3 & SIWE signature tests
    └── widget_tests.dart                  # UI component & form validation tests
```

---

## Running the Application

### 1. Prerequisites
- Flutter SDK 3.29.0 or later
- Android SDK (for Android build) / Xcode (for iOS build)

### 2. Install Dependencies
```bash
cd mobile
flutter pub get
```

### 3. Run Static Analysis
```bash
flutter analyze
```

### 4. Run Automated Tests
```bash
flutter test
```

### 5. Launch Application
For Android emulator (connecting to host machine `10.0.2.2:8000`):
```bash
flutter run -d android
```

For desktop/web:
```bash
flutter run -d linux
# or
flutter run -d chrome
```

---

## Android APK Builds & GitHub Releases

### Automated GitHub CI/CD Releases
Every release or push triggers `.github/workflows/mobile-ci.yml`, which runs static analysis, unit tests, builds the production Android APK, and uploads the artifacts:

1. **GitHub Releases Download**:
   - Go to the repository's [Releases](../../releases) tab on GitHub.
   - Download the latest **`datamint-mobile.apk`** or versioned **`datamint-mobile-v*.apk`**.
   - Verify integrity using the accompanying `.sha256` checksum file.

2. **GitHub Actions Artifacts**:
   - Every CI run (including PRs and branch pushes) archives the built APK in GitHub Actions artifacts under **`datamint-mobile-apk`** (retained for 30 days).

3. **Triggering a Release**:
   - **Git Tag**: Push a version tag:
     ```bash
     git tag v1.0.0
     git push origin v1.0.0
     ```
   - **GitHub UI**: Draft and publish a release under GitHub Releases.
   - **Manual Dispatch**: Go to GitHub Actions $\to$ **Mobile Application CI** $\to$ **Run workflow** with optional custom tag name.

### Local APK Build
To build the universal release APK locally:
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

