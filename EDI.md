# MediTag — Project Documentation (EDI.md)

This is the living reference doc for the MediTag semester project. Update the **Session Log** at the bottom after every work session — what was built, what changed, what's left. Everything above the log is the stable spec; edit it only when a real design decision changes (not every session).

---

## 1. Project Overview

**MediTag** is an NFC-based medical ID tag system. A patient wears/carries an NFC tag. **Hardware purchased: DIGINESS NTAG213 stickers (pack of 10), 13.56 MHz — 144 bytes usable memory.** (Note: earlier design discussion assumed NTAG216's 888 bytes; the actual hardware is NTAG213, which is far tighter — see Section 5a for the resulting byte layout.) Tapping the tag with a phone reveals medical information in tiers:

- **Tier 1 (on-tag, always available):** critical info stored directly on the tag — readable instantly, offline, by anyone (allergies, blood type, emergency contact, critical conditions). Signed so it can be verified as authentic without any network connection.
- **Tier 2 (cloud, gated):** fuller medical record, fetched from the backend, shown only to authorized/authenticated roles (e.g. verified medical personnel) when online.

The core technical problem MediTag solves: **how do you let anyone verify that Tier 1 data on the tag is authentic and untampered, with zero connectivity, on memory-constrained hardware** — while keeping Tier 2 access properly gated and online-only.

## 2. Why This Might Be Patentable (and the honest caveats)

- Section 3(k) of the Indian Patents Act excludes "a computer programme per se" — but MediTag isn't pure software. It has a physical hardware component (the NFC tag) and a specific technical mechanism (offline cryptographic verification under a strict byte budget), which is the right kind of framing to argue a genuine technical effect, not an abstract algorithm.
- **Weak point: novelty.** Offline cryptographic verification (sign server-side, verify client-side with an embedded key) is a well-established pattern (EMV chip cards, digital certificates, etc.). Three prior patents were identified as close prior art during initial research. A real novelty search (via InPASS / Espacenet / Google Patents) is needed before assuming this is clear of prior art — don't rely solely on the three initially-found patents.
- **India requires absolute novelty.** Public disclosure (a demo, a published pitch doc, a presentation, posting this project online) *before filing* can be used as prior art against a later patent application. There's no general grace period — only a narrow exception for government-notified exhibitions. **If a patent is a real goal, file a provisional application (Form 1 + Form 2, ~₹1,600 for individual applicants) before any public demo or presentation.**
- Strongest path to defensible novelty: narrow, specific technical claims (e.g. the exact signing scheme + byte-budget layout + tiering decision logic) rather than a broad "novel dual-mode architecture" claim.
- Not legal advice — a registered Indian patent agent should review actual claims before filing.

## 3. Core Architecture

**Write path:** Python backend signs the Tier 1 payload → writes signed payload to the NFC tag.
**Read path:** Any phone taps the tag → reader app verifies the signature **offline** → Tier 1 data is shown immediately, verified as untampered.
**Tier 2 path:** If the reader app is online and the user is authorized, it calls back to the backend to fetch the full record.

```
Python backend  --signs & writes-->  NFC tag  --tap-->  Reader app (verifies offline)
      ^                                                         |
      |__________________ tier2 fetch (online + authorized) ____|
```

## 4. Tech Stack (decided)

**Reader/writer interface: native/cross-platform app, not a website — confirmed decision.** Reasons: Web NFC (browser NFC access) is unsupported in Safari on iOS/macOS and in any desktop browser, and even on supported Android Chromium browsers it can't issue the low-level chip commands needed for the NTAG213 originality-signature check; a website would also need to load over the internet before it could even attempt to read a tag, undermining the "works fully offline" design goal of Tier 1. A web dashboard is still useful for the *admin/backend* side (issuing tags, managing Tier 2 records, consent, audit logs) — just not for the tap-and-read interaction itself.

- **Reader/writer app:** Flutter (cross-platform), using the `nfc_manager` package for NDEF read/write across iOS and Android.
  - (React Native with `react-native-nfc-manager` was considered as an alternative; Flutter preferred for more reliable low-level NDEF handling.)
- **Backend:** Python, using **FastAPI**.
  - `cryptography` library for signing/verification.
  - Postgres or SQLite for patient records and the tag registry at this scale.
- **Key endpoints (planned):**
  - `POST /tags/issue` — admin generates the Tier 1 payload + signature to write to a new tag.
  - `GET /tags/{id}/tier2` — returns the full record, gated to authorized/authenticated roles only.

## 5. Cryptographic Design

**Decision: use ECDSA (asymmetric), not plain HMAC (symmetric), for Tier 1 signing.**

Why: with HMAC, the same secret key that signs on the server would also need to live inside every reader app to verify — meaning it's extractable by reverse-engineering the app binary, letting anyone forge valid tags. With ECDSA (P-256):
- **Private key** stays server-side only (used to sign).
- **Public key** is baked into every reader app — safe to expose, since it can only verify, not sign.
- Offline verification still works exactly the same way, no network needed.
- Signature size (~64–72 bytes) fits comfortably within the tag's byte budget.

This is also a stronger, more specific patent claim than plain HMAC.

**Stretch/novelty add-on (not yet built):** NTAG21x chips (including the NTAG213 in use) have a factory-programmed ECC-based **originality signature** from NXP that verifies the physical chip itself is genuine (distinct from verifying the data on it). Combining this chip-level authenticity check with the app-level ECDSA data signature would be a two-factor authenticity mechanism — harder to find in prior art, and a stronger patent claim, but adds implementation complexity (may need native platform-channel code beyond what high-level NFC libraries expose).

## 5a. Tier 1 Byte Layout (NTAG213, 144 bytes usable)

With a 64-byte ECDSA (P-256, raw r‖s, not DER) signature and ~4–6 bytes of NDEF overhead, there's roughly 74 bytes left for actual data — not enough for JSON. Tier 1 must use a **compact binary/TLV encoding**, not text.

| Field | Size |
|---|---|
| Format/version byte | 1 byte |
| Blood type (enum, ABO+Rh) | 1 byte |
| Allergy flags (bitmask, up to 16 common allergies) | 2 bytes |
| Critical condition flags (bitmask) | 2 bytes |
| Emergency contact phone (packed BCD) | 5 bytes |
| Tag/patient ID (links to Tier 2 record) | 4 bytes |
| **Data subtotal** | **15 bytes** |
| ECDSA signature | 64 bytes |
| NDEF overhead | ~6 bytes |
| **Total** | **~85 bytes** (of 144 available — ~59 bytes headroom) |

This is provisional at the product level; the v1 bit assignments below are now fixed. The headroom leaves room for a second contact or a short free-text field if needed later.

### 5b. Implemented wire contract (v1)

The unsigned 15-byte value is encoded big-endian as `version (1) | blood enum (1) | allergy mask (2) | condition mask (2) | 10-digit Indian phone in packed BCD (5) | tag ID (4)`. The server signs those 15 bytes with ECDSA P-256/SHA-256, converts the DER result to a fixed 64-byte raw `r || s`, and appends it. The final tag payload is exactly 79 bytes.

Store it in one NDEF record with TNF `unknown` and empty type/identifier. The NDEF message is 82 bytes; its Type 2 TLV encoding including terminator is 86 bytes, leaving 58 bytes of NTAG213 memory unused.

Bit assignments are now fixed for v1:

- Allergies, bits 0–12: penicillin, sulfonamides, aspirin/NSAIDs, contrast dye, latex, peanuts, tree nuts, milk, eggs, shellfish, soy, wheat, insect stings.
- Conditions, bits 0–10: diabetes, epilepsy, heart disease, hypertension, asthma, COPD, kidney disease, liver disease, anticoagulants, immunocompromised, pregnancy.

## 6. Build Priority (core first)

Build and demo this loop solidly before adding anything else:

1. NFC tag read/write with the tiered data structure (get the byte-budget layout — Tier 1 fields — working reliably on real hardware).
2. ECDSA signing (backend) and offline verification (app) — the central technical claim. Demo: a legitimate tag verifies; a tampered tag fails.
3. Role-gating logic — who sees Tier 2, and how that's enforced app-side.
4. A working reader app demo (even simple) showing the tiered reveal.

Once that loop is solid, layer in (in rough priority order):
- Per-tag unique keys / key derivation (if moving beyond a single shared server keypair)
- NTAG213 originality signature check (chip-level anti-cloning)
- Deferred features (below)

## 7. Deferred / Future Features (explicitly not in current build)

- **ABDM/ABHA integration** (India's national health ID + consent-based record exchange) — deliberately deferred. Sandbox registration is at `sandbox.abdm.gov.in`; free and open to student projects; relevant building blocks would be ABHA + HIE-CM (consuming records as an HIU, not providing them). To be added later once the core system works.
- **Three-tier connectivity fallback** — an SMS-based fallback tier for areas with no data connection but 2G/SMS signal (currently the design is binary online/offline).
- **Auto-trigger on impact** — using a paired accelerometer/impact sensor to auto-notify emergency contacts/services on crash detection, rather than requiring a manual tap.
- **108/112 emergency services API integration** — where available at the state level.

## 8. Open Questions / Not Yet Decided

- Production authentication/authorization scheme for Tier 2 access (the MVP uses separate admin and clinician bearer tokens; who counts as a verified medical professional still needs a real identity-verification design).
- Whether to pursue per-tag unique keys (HKDF-derived) vs a single backend keypair for the MVP.
- Patent filing timeline — whether/when to file a provisional before any public demo.

---

## Session Log

*Add a new dated entry after each work session. Keep entries factual: what was actually built/decided/changed, and what remains.*

### Template for new entries
```
### YYYY-MM-DD
**Done:**
-

**Decisions made:**
-

**Remaining / next steps:**
-
```

### 2026-09-12 (app vs. website decision confirmed)
**Done:**
- Considered switching the reader/writer interface from a native/cross-platform app to a website.
- Decided against it and confirmed sticking with the app — reasons documented in Section 4 (iOS/Safari has no Web NFC support, low-level chip commands needed for the originality-signature check aren't exposed to browsers, and a website would need connectivity just to load before it could attempt an offline tag read).

**Remaining / next steps:**
- Proceed with Flutter app + Python/FastAPI backend as planned.
- A web dashboard remains a good fit for the admin/Tier 2 management side only.

### 2026-09-12 (hardware purchased)
**Done:**
- Purchased hardware: DIGINESS NTAG213 stickers (pack of 10) — 144 bytes usable memory, not the 888 bytes originally assumed (NTAG216).
- Reworked Tier 1 byte layout to fit within 144 bytes given a 64-byte ECDSA signature: ~15 bytes of compact binary-encoded data (blood type, allergy/condition bitmasks, packed phone number, tag ID) + 64-byte signature + NDEF overhead ≈ 85 bytes total, ~59 bytes headroom.
- Decided Tier 1 payload must use compact binary/TLV encoding, not JSON — the byte budget doesn't allow text-based formats.

**Remaining / next steps:**
- Define exact bitmask assignments for allergy flags and condition flags.
- Confirm packed-BCD phone number format.
- Move on to implementing NFC read/write + ECDSA sign/verify loop against actual NTAG213 hardware.

### 2026-09-12 (project kickoff)
**Done:**
- Defined core concept: tiered NFC medical tag (Tier 1 on-tag, Tier 2 cloud-gated).
- Explored Indian patentability (Section 3(k), novelty concerns, absolute novelty disclosure timing).
- Decided on tech stack: Flutter (reader app) + Python/FastAPI (backend).
- Decided to switch signing scheme from HMAC (symmetric) to ECDSA (asymmetric) for offline verification security.
- Identified NTAG216 originality signature as a possible stretch feature for chip-level anti-cloning.
- Explicitly deferred ABDM/ABHA integration to focus on core build first.

**Remaining / next steps:**
- Design exact Tier 1 payload byte layout.
- Implement ECDSA sign (backend) / verify (app) loop.
- Get basic NFC read/write working in Flutter with `nfc_manager`.
- Build minimal FastAPI backend with `/tags/issue` endpoint.

### 2026-09-13 (MVP protocol and implementation)
**Done:**
- Implemented a FastAPI backend with `POST /tags/issue`, `POST /tags/verify`, `GET /public-key`, and role-gated `GET /tags/{id}/tier2`; SQLite stores the MVP tag registry and Tier 2 demo records.
- Implemented P-256 signing server-side with a persistent private key excluded from Git; the reader receives only a 65-byte public key at provisioning time.
- Created the Flutter Android/iOS reader project with NDEF scan support, Tier 1 binary decoding, and offline P-256 verification.
- Added automated tests for payload decode, tamper rejection, and a real Python-issued payload verifying in Flutter. Flutter analysis reports no issues.
- Defined and implemented v1 allergy/condition bit assignments, 10-digit Indian packed-BCD phone format, and the one-record NDEF wire format (Section 5b).

**Decisions made:**
- Retain fixed 64-byte raw `r || s` signatures on the tag. The Flutter reader verifies with a pure-Dart P-256 implementation so Android and iOS use the same signature representation; Android's system verifier expects DER while iOS accepts raw signatures.
- MVP Tier 2 gating uses distinct admin and clinician tokens only. It demonstrates enforcement but is not a production medical-identity solution.

**Remaining / next steps:**
- Provision the generated public key into the reader, issue a test record, and write/read it on a physical NTAG213.
- Add an admin issue/write screen (or a controlled writer flow) to write the returned payload as the specified NDEF record.
- Replace demo-token Tier 2 access with a decided clinician authentication and consent model.
- Add the NTAG213 originality-signature check as the next security stretch goal.

### 2026-09-13 (frontend-first product flow)
**Done:**
- Replaced the single-purpose reader screen with a complete clickable Flutter frontend for both patient and doctor journeys.
- Added role selection/login UI; patient screens for home, medical ID, health profile, emergency contacts, and privacy; doctor screens for clinician status, NFC scanning, patient lookup, and access-audit/profile states.
- Kept the real NFC scan and offline signature verification hook inside the doctor Scan tab; it becomes live once the issuer public key is provisioned.
- Marked product functions that still need backend connection (registration, credential verification, profile edits, consent, Tier 2 request, audit history, tag issuing) rather than pretending they are already secure/live.
- Ran Flutter analysis and tests successfully.

**Decisions made:**
- Build the frontend first to make all user journeys and feature scope visible, then connect each screen to the already-started backend in vertical slices.

**Remaining / next steps:**
- Review the screen flows and refine the patient/doctor feature list before implementing the real login and registration API.
- Build the clinician tag-issue/write screen next, then connect patient profile editing and Tier 2 consent/access flows.

### 2026-09-13 (frontend navigation and visual system)
**Done:**
- Changed the Patient dashboard's “View medical ID” and “Emergency contacts” actions from instructional messages to direct navigation to the My ID and Health tabs.
- Reworked the shared visual system from red/white to white, light blue, and soft pastel accents; blue is now the primary brand/action color.
- Reserved rose/red visual treatment for allergy warnings, while conditions, medication, contacts, and status use distinct calm accent colors.
- Flutter analysis and tests pass after the UI update.

**Decisions made:**
- Use red only where it communicates clinical caution (especially allergies), not as the app-wide brand color.

### 2026-09-13 (patient home and health consolidation)
**Done:**
- Merged the patient Health content into the Home dashboard and removed the separate Health navigation tab.
- Home now contains tag status, medical-profile summaries and edit affordances, emergency contacts, tag-data privacy explanation, and safety guidance.
- Added an emergency-contact bottom sheet with primary/secondary contact preview.
- Flutter analysis and tests pass after the navigation consolidation.

**Decisions made:**
- Patient Home is the single health overview; My ID remains a dedicated emergency-card view and Profile remains account/privacy focused.

### 2026-09-13 (session handoff)
**Done:**
- MVP backend, signed Tier 1 protocol, Flutter NFC verification core, and the frontend-first patient/doctor app flow are in the workspace.
- Patient Home and Health are consolidated; its navigation is now Home, My ID, and Profile.
- The Flutter project has passed analysis and protocol/interoperability tests after the latest UI changes.

**Current state / important notes:**
- Patient and doctor login screens are frontend prototypes only; they do not yet authenticate a real account.
- Patient data currently shown in the UI is demo content. Profile editing, registration, clinician credential verification, consent, Tier 2 retrieval, audit history, and tag issuing are represented in the UI but are not connected end-to-end.
- The Doctor Scan tab contains the real offline verification hook. It needs the backend's provisioned public key and a physical NDEF-written NTAG213 to test scanning.

**Recommended next-session order:**
- Review the frontend on the Android emulator/phone and make any final UX changes.
- Implement real patient registration/login and clinician login/verification, starting with a secure backend auth model.
- Connect patient health-profile edits to the backend and regenerate a signed Tier 1 payload when on-tag fields change.
- Build the clinician tag-issue/write workflow, then test the complete issue → write → scan → verify loop on real NTAG213 hardware.
