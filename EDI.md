# MediTag — Project Documentation (EDI.md)

This is the living reference doc for the MediTag semester project. Update the **Session Log** at the bottom after every work session — what was built, what changed, what's left. Everything above the log is the stable spec; edit it only when a real design decision changes (not every session).

---

## 1. Project Overview

**MediTag** is an NFC-based medical ID tag system. A patient wears/carries an NFC tag. **Hardware purchased: DIGINESS NTAG213 stickers (pack of 10), 13.56 MHz — 144 bytes usable memory.** (Note: earlier design discussion assumed NTAG216's 888 bytes; the actual hardware is NTAG213, which is far tighter — see Section 5a for the resulting byte layout.)

The app has **three distinct access surfaces**, confirmed as of 2026-09-14:

1. **Anonymous bystander tap (no login)** — anyone taps the tag with any phone and sees Tier 1 critical info instantly, offline, cryptographically verified. This is the emergency-access core of the product and is why Tier 1 has to work with zero connectivity and zero account — a stranger helping an unconscious person has neither. This is the flow already specced in [`FRONTEND_DESIGN.md`](./FRONTEND_DESIGN.md) and currently being rebuilt.
2. **Citizen login (patient's own app)** — the tag owner logs in (email/phone + password, with forgot-password) to manage their own profile: view their own basic info, update their medical profile over time, and upload fuller medical history to the cloud (this becomes the Tier 2 data doctors see). New vs. returning users are distinguished by checking whether their email/phone pairing already has a MediTag profile.
3. **Doctor login (clinician app)** — a verified clinician logs in, then taps a tag from a "Tap to Scan" home screen to see the patient's full structured record (Tier 2, gated/authorized access).

- **Tier 1 (on-tag, always available):** critical info stored directly on the tag — readable instantly, offline, by anyone (allergies, blood type, emergency contact, critical conditions). Signed so it can be verified as authentic without any network connection.
- **Tier 2 (cloud, gated):** fuller medical record, entered/uploaded by the citizen via their own app, fetched from the backend and shown only to authenticated, verified doctors when online.

The core technical problem MediTag solves: **how do you let anyone verify that Tier 1 data on the tag is authentic and untampered, with zero connectivity, on memory-constrained hardware** — while keeping Tier 2 access properly gated to authenticated doctors and put there by the citizen themselves.

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

## 3a. Citizen & Doctor App — Information Architecture

**Citizen app (patient's own account):**
- **Login** — email or phone + password, with forgot-password flow.
- On successful login, email/phone pairing is checked against existing profiles → **new user** goes to profile creation; **returning user** goes straight to their home tab.
- Bottom tab bar (three icons, Spotify/Instagram-style):
  - **Home** — the citizen's own basic offline details (what's currently on their tag) plus other profile info at a glance.
  - **Create/Update** — where the citizen edits their medical profile over time and uploads extra medical history/documents, which is saved to the cloud (this becomes their Tier 2 record).
  - **Settings** — account settings.

**Doctor app (clinician account):**
- **Login** — doctor ID is verified as part of login (exact verification method: open question, see Section 8).
- Home screen: a large **"Tap to Scan"** button, front and center.
- On scan: the doctor sees the patient's information in a proper structured form — this is the Tier 2 authorized view.

**How this connects to the existing Tier 1/Tier 2 design:** the anonymous bystander flow (Section 1, surface 1) and its screens in `FRONTEND_DESIGN.md` are unaffected by this — that spec and the in-progress rebuild still stand as-is for the no-login tap flow. The citizen and doctor apps are two additional, separate login-gated surfaces layered on top. **`FRONTEND_DESIGN.md` currently only specs the anonymous reader-flow screens — the citizen and doctor login/profile/scan screens still need their own design pass**, using the same `MT*` component library and token system for visual consistency.



**Frontend rebuild:** the first UI build wasn't working and is being rebuilt against a dedicated design spec — see [`FRONTEND_DESIGN.md`](./FRONTEND_DESIGN.md) for the full visual language (colour/type/shape tokens, component library, screen-by-screen notes) and rebuild instructions. Adapted from a design system the project owner liked on another project: tinted page, floating white cards, ink-tinted shadows, no borders.

**Reader/writer interface: native/cross-platform app, not a website — confirmed decision.** Reasons: Web NFC (browser NFC access) is unsupported in Safari on iOS/macOS and in any desktop browser, and even on supported Android Chromium browsers it can't issue the low-level chip commands needed for the NTAG213 originality-signature check; a website would also need to load over the internet before it could even attempt to read a tag, undermining the "works fully offline" design goal of Tier 1. A web dashboard is still useful for the *admin/backend* side (issuing tags, managing Tier 2 records, consent, audit logs) — just not for the tap-and-read interaction itself.

- **Reader/writer app:** Flutter (cross-platform), using the `nfc_manager` package for NDEF read/write across iOS and Android.
  - (React Native with `react-native-nfc-manager` was considered as an alternative; Flutter preferred for more reliable low-level NDEF handling.)
- **Backend:** Python, using **FastAPI**.
  - `cryptography` library for signing/verification.
  - Postgres or SQLite for patient records and the tag registry at this scale.
  - **Newly required (not yet built):** user accounts + password auth for both citizen and doctor roles, forgot-password/email flow, doctor identity verification, and file/document storage for citizen-uploaded medical history (Tier 2 source data). This is a meaningfully bigger backend than the original two-endpoint design — see Section 8 for what's still undecided here.
- **Key endpoints (planned):**
  - `POST /tags/issue` — admin generates the Tier 1 payload + signature to write to a new tag.
  - `GET /tags/{id}/tier2` — returns the full record, gated to authenticated doctors only.
  - `POST /auth/citizen/login`, `POST /auth/citizen/register`, `POST /auth/citizen/forgot-password` — citizen account auth.
  - `POST /auth/doctor/login` (+ identity verification step, TBD) — doctor account auth.
  - `PUT /citizen/profile`, `POST /citizen/documents` — citizen profile updates and medical history uploads.

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

This is provisional — exact bitmask assignments (which allergies/conditions map to which bits) still need to be defined. The headroom leaves room for a second contact or a short free-text field if needed later.

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

- Exact bitmask assignments (which specific allergies/conditions map to which bit — the byte layout itself is settled in Section 5a, but the bit-to-meaning mapping isn't).
- ~~Authentication/authorization scheme for Tier 2 access~~ — resolved 2026-09-14: separate citizen and doctor logins (Section 3a). Still open beneath that:
  - How doctor identity is actually verified at login (medical registration number lookup? manual admin approval? a third-party API?).
  - Session/token scheme for both citizen and doctor logins (JWT? session cookies?).
  - Where/how uploaded medical documents are stored (raw file storage vs. structured fields vs. both) and any size/type limits.
  - Password reset delivery mechanism (email required at minimum — is phone/SMS reset also needed?).
- Whether to pursue per-tag unique keys (HKDF-derived) vs a single backend keypair for the MVP.
- Patent filing timeline — whether/when to file a provisional before any public demo.
- Citizen and doctor app screens still need a `FRONTEND_DESIGN.md`-style design pass (Section 3a) — not yet started.

---

## Session Log

*Add a new dated entry after each work session. Keep entries factual: what was actually built/decided/changed, and what remains.*

### 2026-09-23 (Android offline write demo)
**Done:**
- Added an Android-capable NDEF writer that writes the 79-byte signed Tier 1 payload as one unknown-type record with empty type and identifier.
- Connected the Issue Tag screen to `POST /tags/issue` using a build-time demo admin token, then writes the returned payload to a writable NTAG213 without locking it.
- Added capacity and writability checks, local-network HTTP guidance, Android cleartext support for the demo server, and a review-ready write → read → offline-verify flow.
- Added the direct `ndef_record` dependency and kept cloud medical history outside this milestone.

**Remaining / next steps:**
- Build/install the debug APK on a physical NFC Android phone and validate a real NTAG213 write/read/tamper cycle.
- Remove the demo admin token from the mobile client before any production release; move issuance behind a protected admin surface.

### 2026-09-23 (repository and code organization)
**Done:**
- Converted the website from an unconfigured nested Git repository into normal files in the main MediTag repository; preserved its original standalone history in a verified local Git bundle before conversion.
- Added repository-wide editor, line-ending, generated-file, secret, and cache rules.
- Replaced the generic website starter documentation and package name with MediTag-specific documentation and naming.
- Split the 1,700-line Flutter entry file into feature-owned reader, access, citizen, and doctor modules while preserving the existing private widget boundaries and behavior.
- Added a concise project milestone checklist and documented the repository and Flutter source layouts.
- Cleared the website lint warnings; website lint/build, Dart analysis, and a backend protocol/signature smoke test pass.

**Remaining / next steps:**
- Diagnose the local Flutter test runner, which currently stalls before producing test output even though static analysis passes.
- Continue separating UI state from the large citizen and doctor presentation modules as their real API integrations are implemented.

### 2026-09-18 (website-aligned app redesign)
**Done:**
- Aligned the Flutter app with the website's visual system: pale periwinkle canvas, ink-dark primary surfaces, white floating cards, DM Sans display type, Inter body type, tinted tags, rounded icon tiles, and ink-tinted elevation.
- Expanded the shared `MT*` component library with branded headers, overlines, avatars, icon tiles, dark/orchid card variants, accent actions, responsive page headings, mint/critical verification bands, and a dark blood-type stat card.
- Redesigned the access portal, verified emergency profile, citizen dashboard, citizen/doctor sign-in, and clinician workspace with responsive mobile/tablet/desktop layouts.
- Kept color, radius, and elevation decisions centralized in `tokens.dart`; Dart static analysis and all 9 automated tests pass.
- Rendered the access portal at a 390×844 mobile viewport and fixed the responsive overline overflow found during visual QA.

**Decisions made:**
- The app now treats the website as the source of truth for visual hierarchy while preserving native NFC and accessibility behavior.
- Primary actions use the website's ink-dark treatment; accent actions on dark panels use the lighter periwinkle blue for contrast.

**Remaining / next steps:**
- Connect the redesigned citizen and clinician surfaces to the planned authentication, profile, consent, and Tier 2 APIs.
- Verify the final build on representative physical Android and iOS devices, including the native NFC permission and scan states.

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

### 2026-09-14 (three-surface frontend)
**Done:**
- Reworked the Flutter entry experience around Citizen, Doctor, and no-login emergency-reader access, matching the three-surface architecture in Section 3a.
- Added citizen sign-in, forgot-password affordance, profile-pairing preview, and a three-tab Home/Create/Settings experience.
- Added doctor sign-in with clinician-ID verification affordance and a dedicated Tap to Scan home screen that opens the existing NFC reader flow.

**Decisions made:**
- Until the planned account APIs exist, citizen profile pairing and clinician verification are explicitly labelled frontend previews rather than represented as real authentication.
- Anonymous NFC reading remains available from the access portal and retains the offline signed Tier 1 flow.

**Remaining / next steps:**
- Implement the citizen and doctor authentication, profile-pairing, document-upload, and clinician-verification backend endpoints.
- Connect citizen Create updates to Tier 2 storage and route successful doctor scans directly into authorized structured Tier 2 records.

### 2026-09-14 (citizen + doctor login architecture)
**Done:**
- Confirmed the app has three access surfaces, not one: (1) anonymous bystander tap — no login, offline Tier 1 — unchanged from the existing design/rebuild; (2) citizen login — patient manages their own profile via a 3-tab (Home/Create/Settings) app, uploads medical history to the cloud; (3) doctor login — verified clinician, "Tap to Scan" home screen, sees full structured Tier 2 record on scan.
- Clarified this explicitly with the project owner because it changes the core architecture — confirmed the anonymous bystander flow is preserved alongside the two new login surfaces, not replaced by them.
- Documented citizen/doctor information architecture in Section 3a.
- Expanded backend requirements: citizen + doctor auth, forgot-password, doctor identity verification, document upload for medical history — noted as a meaningfully bigger backend than originally scoped.

**Remaining / next steps:**
- Citizen and doctor app screens need their own `FRONTEND_DESIGN.md`-style design pass, using the same `MT*` component/token system.
- Resolve the newly opened backend questions in Section 8 (doctor identity verification method, session/token scheme, document storage approach, password reset delivery).
- Sequencing: the in-progress reader-flow rebuild (anonymous bystander flow) continues as planned; citizen/doctor login apps are a new, separate build phase on top of it.

### 2026-09-14 (frontend redesign)
**Done:**
- First UI build (by codex) was unusable — decided on a full rebuild rather than patching it.
- Wrote `FRONTEND_DESIGN.md`: complete design spec (colour/type/shape/motion tokens, `MT*` component library, screen-by-screen notes, rebuild instructions), adapted from a design language the project owner liked on another project (periwinkle-tinted page, floating white cards, ink-tinted shadows, no borders).

**Remaining / next steps:**
- Rebuild the app UI against `FRONTEND_DESIGN.md` — tokens file first, then the `MT*` component library, then screens in the documented order.
- Log which screens are complete vs. still stubs once the rebuild is underway.

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
