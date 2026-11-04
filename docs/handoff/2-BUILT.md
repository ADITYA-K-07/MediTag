# MediTag: what's built so far (state as of 4 Nov 2026)

> Handoff doc 2 of 3. Goal: `1-GOAL.md`. Next steps: `3-NEXT.md`.

## Where things live

| Thing | Value |
|---|---|
| Repo | https://github.com/ADITYA-K-07/MediTag (local: `D:\MediTag`, Windows) |
| Live website | **https://meditag-lovat.vercel.app** (Vercel Hobby, deploys `main`, Root Directory `web`) |
| Firebase project | `meditag-598f1` (Spark). Auth: phone ✓ (SMS region **India allowed**), email/password ✗ not enabled yet. Firestore in asia-south1. |
| Firebase test phone numbers | `+91 9999900001` (citizen), `…002` (doctor), `…003` (admin), all with code `123456` |
| Authorized domains | localhost, meditag-lovat.vercel.app |
| Supabase | project URL `https://bwbyfjxrqxcwfztrjfei.supabase.co`, private bucket `records` (20 MB, PDF/images only) |
| Tag-signing public key (key id 1) | `0494ee13c04b79f122fdb9fe44688546acb20f204be253c3566af771cc5cea53d036b8954b26e5c43b95789b31c8deb1dd461296c93a85649e4fd94e1db0f1421b` |
| Secrets | Only in `web/.env.local` (git-ignored) and Vercel env vars. **Never commit or paste them.** Template: `web/.env.example`. |
| Android debug key fingerprints | SHA-1 `1E:E5:54:D4:D9:45:AF:85:09:98:4F:57:37:5C:57:94:FF:D1:17:30`, SHA-256 `54:7B:13:A8:88:84:A3:33:6F:37:B0:5F:E7:15:7D:1B:8C:80:03:8A:DF:58:E3:63:09:F7:70:8F:1F:D7:BD:7F`. **The user must add these to the Firebase Android app** before phone login works in the app. |

## Git state

- `main` holds everything up to and including PR #5 (website live and working).
- **Branch `feature/app-tag-programming`** (commit `f827872`) is pushed, but **its PR is not opened yet**. It contains the Android app's login and tag programming. Open it here: https://github.com/ADITYA-K-07/MediTag/compare/main...feature/app-tag-programming
- This handoff folder (`docs/handoff/`) was written on that branch.
- The `gh` CLI is **not installed**. The user opens and merges PRs themselves in the browser, so give them a pre-filled compare link.

## Repository layout

```
web/      Next.js 16.4 (App Router, Turbopack, Cache Components ON) + Tailwind v4: website AND server API
  src/app/            pages: / (home), /scan, /e/[tagId], (account)/login, (account)/citizen, (account)/citizen/profile
  src/app/api/        route handlers (see the API table below)
  src/server/         server-only: env.ts, firebase.ts (Admin SDK), http.ts (handle/requireUser/errors),
                      tags.ts, doctors.ts, files.ts (Supabase), activity.ts (audit + notifications)
  src/server/core/    pure, unit-tested: payload.ts, envelope.ts, signing.ts, ndef.ts, ids.ts, secrets.ts, access.ts, tagWrite.ts
  src/lib/            browser: tag/ (envelope decode + WebCrypto verify, Web NFC), firebase/client.ts, profile.ts, apiClient.ts, api.ts, demo/
  src/components/     EmergencyCard, Icon/Logo, home/ProfileCard (drawn hero card), auth/AuthProvider, account/AccountShell
  scripts/            generate-keys.mjs (npm run keys), make-test-vectors.ts (npm run vectors)
app/      Flutter app (package com.meditag.app)
  lib/tag/            envelope.dart (verify), payload.dart, tag_reader.dart (read NDEF), ndef_encoder.dart, ntag216.dart, tag_session.dart
  lib/screens/        scan_screen (bystander), login_screen, citizen_home (+AccountGate), tag_write_screen (program/update)
  lib/api/            meditag_api.dart (calls web /api with Firebase ID token; base URL via --dart-define=API_BASE_URL)
  dart_defines.json   TAG_PUBLIC_KEYS (public key); build with --dart-define-from-file=dart_defines.json
schema/   tag-payload.schema.json, README.md (envelope spec), test-vectors.json (shared by web + app tests)
design/   tokens.json → web/src/styles/tokens.css + app/lib/theme/tokens.dart; mockups/ (HTML mockups)
firestore.rules, firestore.indexes.json, firebase.json, .firebaserc (deployed: `firebase deploy --only firestore`)
PLAN.md, SETUP.md (free-tier account setup), README.md
```

## Done and verified

**Shared tag security**
- Signed envelope, NTAG216 byte budget (a full profile uses 427 of 888 bytes), tamper detection.
- `schema/test-vectors.json` is checked by web tests **and** app tests, so all sides agree byte for byte.

**Website (live)**
- **Home page** in the new design: periwinkle background, a heavy headline ("One tap can tell them how to help."), navy pill buttons, the drawn tilted profile card, then How it works, the navy privacy band, role cards and the footer wordmark.
- **/scan:** Web NFC on Android Chrome; demo buttons (genuine and tampered tag) appear only when no public key is configured. A "Tag found" tick animation.
- **/e/[tagId]:** reads Firestore live (`await connection()`), and shows revoked, unknown or unavailable states with a Call 108 button.
- **/login:** phone OTP with invisible reCAPTCHA. On first login it creates `users/{uid}` with role citizen. **Tested live by the user ✓.**
- **/citizen dashboard:** profile strength ring, live tag list with **Revoke**, recent notifications.
- **/citizen/profile editor:**
  - every field, each with an **On tag / Cloud only** switch
  - a live bystander preview and an 888-byte meter that matches the server exactly (pinned by a test)
  - saves offline through Firestore's local cache. **Tested by the user ✓** (the profile is saved in Firestore).
- **Light mode only** (`color-scheme: light`); motion is reduced when the user's device asks for it.

**Server API** (all require `Authorization: Bearer <Firebase ID token>`; return 401 without one)

| Route | Purpose |
|---|---|
| `POST /api/tags {label}` | Prepare a new tag: signed payload + password (max 3 active) |
| `POST /api/tags/:id/confirm {nfcUid}` | Mark the tag active after the app read it back |
| `POST /api/tags/:id/rewrite` | Re-sign the profile and return the tag's password (active or pending tags) |
| `POST /api/tags/:id/revoke` | Deactivate the tag |
| `POST /api/access {tagId,nfcUid,tappedAt}` | Doctor: 24 h grant (`accessGrants/{doctorUid}_{patientUid}`), audit, notify |
| `POST /api/admin/doctors/:uid/review {approve,reason}` | Admin: set the doctor claims |
| `POST /api/files/upload` / `download` | Supabase signed upload URL / 5-minute download link (owner or granted doctor) |

- **Firestore rules are deployed.** Collections: `users`, `users/{uid}/notifications`, `emergencyProfiles`, `medicalRecords/{uid}/entries`, `doctors`, `tags`, `tagSecrets` (server-only), `accessGrants`, `publicScans`, `auditLogs`.
- **Supabase** round-trip tested: upload, a 60-second download link, the public URL is blocked, and `.txt` uploads are rejected.

**Android app (branch `feature/app-tag-programming`, not merged)**
- **Scan screen** (bystander): offline verify, "Tag found" animation, emergency card with call and SMS buttons. A **"My tags"** button opens the account screens.
- **Login:** Firebase phone OTP.
- **Citizen home:**
  - **Program a new tag** (choose a label → API prepare → hold the tag → check it's an NTAG216 → write NDEF → read back → lock with PWD/PACK, AUTH0 = 4 → API confirm)
  - **Update a tag** (read the URL → tagId → API rewrite → authenticate → rewrite)
  - a link to the website profile editor
- **23 tests pass**, including a fake NTAG216 (write, lock, a stranger's write refused, rewrite, wrong password, NTAG213 refused, blank Capability Container written, read-only tag refused, a NAK that the phone reports as an exception). `flutter analyze` is clean.
- Hardened for real phones: a wrong password shows the right message even when Android throws on the NAK; a blank tag gets its NDEF Capability Container; a tag locked but never confirmed (lost signal) can be finished with **Update a tag** (the server now allows rewrite on `pending` tags, and re-checks the 3-tag limit when a pending tag is confirmed).
- **The debug APK builds** (`app/build/app/outputs/flutter-apk/app-debug.apk`, about 150 MB). **Not yet run on a real phone or tag.**

## Gotchas already solved (don't undo these)

- **Vercel crash `ERR_REQUIRE_ESM` (jose)**
  - Cause: `firebase-admin/auth` → `jwks-rsa` → ESM-only `jose` 6.
  - Fix: in `web/package.json`, `"overrides": { "jwks-rsa": { "jose": "^4.15.9" } }`, plus `engines.node "24.x"`.
  - To test it locally the way Vercel runs it: `NODE_OPTIONS=--no-experimental-require-module`.
- **Next.js 16 behaves differently from older versions.**
  - Read `web/node_modules/next/dist/docs/` before writing Next code (see `web/AGENTS.md`).
  - Cache Components is on: anything reading params or data must be inside `<Suspense>` or call `await connection()`.
  - `PageProps` and `RouteContext` are global types.
- **Firestore/Turbopack dependency:** `@opentelemetry/api` must stay installed.
- **Kotlin**
  - Firebase Auth 25 needs **Kotlin 2.4.21**, set in `app/android/settings.gradle.kts`.
  - Use `kotlin { compilerOptions { jvmTarget… } }`, not `kotlinOptions`.
  - Keep `kotlin.incremental=false` in `gradle.properties`, because the project on D: and the pub cache on C: break incremental caches.
- **Firebase SMS region policy** must allow **IN**. It was empty, which blocked every login.
- **reCAPTCHA:** the in-app automated browser gets image challenges, which the agent must never solve. The user tests logins in their own Chrome.
- **The user's Chrome extension** adds `fdprocessedid` attributes, which causes a harmless hydration warning in dev.
- The Vercel domain changed from `medi-tag-beta…` to **`meditag-lovat.vercel.app`**.
- `PUBLIC_BASE_URL` in Vercel must be `https://meditag-lovat.vercel.app`; it's written onto every tag. The user was asked to set it, but it **hasn't been confirmed**.

## How to run and check

```bash
cd web && npm test && npm run typecheck && npm run lint && npm run build   # 33 tests
cd web && npm run dev                                                       # http://localhost:3000
cd app && flutter test && flutter analyze                                   # 20 tests
cd app && flutter build apk --debug --dart-define-from-file=dart_defines.json
firebase deploy --only firestore        # after editing firestore.rules
node design/build-tokens.mjs            # after editing design/tokens.json
```
