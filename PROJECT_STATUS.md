# MediTag Project Status

Last reviewed: 2026-09-23

## Current milestone

The repository is an integrated prototype: the signed Tier 1 protocol,
backend issue/read services, native reader UI, and browser previews exist.
Production identity, consent, persistence, and physical-device validation are
the main unfinished areas.

## Complete

- Compact NTAG213 Tier 1 binary protocol
- P-256 signing in Python and offline verification in Flutter
- FastAPI tag issuance, public-key, verification, and Tier 2 endpoints
- SQLite-backed demo tag registry
- Native NFC read flow with verified and tampered-tag states
- Citizen, clinician, and anonymous-reader UI surfaces
- Responsive web previews for public, citizen, and clinician journeys
- Shared visual tokens and reusable Flutter components

## Target for the 75% milestone

- [x] Implement the backend-issued signed payload → raw NDEF write path
- [ ] Write and verify it on a physical NTAG213 tag
- [ ] Verify read, offline-read, and tamper-failure behavior on Android
- [ ] Verify the supported NFC flow on iOS
- [ ] Connect a clinician scan to a real Tier 2 API response
- [ ] Keep backend, Flutter, and website checks reproducibly green

## After the 75% milestone

- Citizen registration, login, and password recovery
- Clinician identity verification and production authorization
- Persistent citizen profile editing and document upload
- Consent and access-audit workflows
- Production deployment, secret management, and database migration strategy
- Optional per-tag key derivation and NTAG213 originality verification

Detailed technical decisions and session history remain in [`EDI.md`](./EDI.md).
