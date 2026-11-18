# ADR 0002: Unified Identity with Dual Capabilities

## Status
Accepted

## Context
Marketplace platforms often make the mistake of creating separate user tables or mutually exclusive roles (e.g. `Creator` vs `Contributor`). In practice, AI researchers frequently contribute data to test other campaigns, and active contributors sometimes launch small custom collection requests.

## Decision
We implement a single user model (`users`) where capabilities are decoupled from the user row:
1. `UserCapability` stores active permissions (`CONTRIBUTOR`, `CREATOR`, `REVIEWER`, `ADMIN`).
2. An individual user can possess multiple capabilities simultaneously.
3. Access control is enforced via route-level dependency injection (`require_capability(CapabilityType.CREATOR)`).

## Consequences
- **Positive:** Frictionless onboarding; unified wallet connection; shared reputation and transaction history.
- **Negative:** UI must support switching roles or views seamlessly without account re-login.
