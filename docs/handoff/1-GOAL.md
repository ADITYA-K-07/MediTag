# MediTag: the goal (what we are building)

> Handoff doc 1 of 3. Read with `2-BUILT.md` (current state) and `3-NEXT.md` (what to do next).
> Full original design: `PLAN.md` at the repo root. Mockups: `design/mockups/`.

## The problem

When an unidentified person is hurt in an accident in India and taken to hospital, doctors have no
medical history: no name, blood group, allergies, emergency contact or past surgeries. Treatment is
delayed or risky. Bystanders at the scene can't reach the person's family either.

## The solution

Each citizen gets **up to 3 NFC tags (NTAG216)**: a wallet card, a car sticker and a wearable (bracelet
or keychain). Tapping any tag with a phone gives:

1. **Tier 1: emergency info, stored on the tag itself, readable offline by anyone.**
   This covers name, age, blood group, allergies, critical conditions, medicines and emergency contacts,
   and the citizen chooses which fields go on the tag. The data is **digitally signed** by the server
   (ECDSA P-256), so the app and website can show **"Verified"** or **"Unverified (may be tampered)"**
   without internet.
2. **Tier 2: full medical history in the cloud, for verified doctors only.**
   This covers surgeries, diagnoses, lab reports, scans, prescriptions and doctor notes.
   - A doctor gets access only after **physically tapping the patient's tag** (proof of presence).
   - Access lasts 24 hours, every view is logged, and the patient is notified.

## Users and roles

| Role | Login | Can do |
|---|---|---|
| **Bystander / public** | none | "Scan a MediTag" → see Tier 1, call family, call 108/112, send GPS location by SMS |
| **Citizen** | phone OTP | Edit emergency profile, choose on-tag fields, upload records, program/update/revoke tags (max 3), see access log |
| **Doctor** | email + verification | Sign up with Medical Council registration and licence. Once verified, tap a tag to get 24 h full-record access and add clinical notes. |
| **Admin** | admin claim | Approve or reject doctors, audit log, security alerts |

## What a tag holds (NTAG216, 888 bytes of user memory)

One NDEF message with 3 records, in this order:
1. **URI**: `https://<site>/e/<tagId>`. Comes first so any phone without the app (including iPhones) opens the website.
2. **MIME `application/vnd.meditag.v1`**: a binary envelope `[version 1][len 2][JSON][keyId 1][signature 64]`. Spec in `schema/README.md`; schema in `schema/tag-payload.schema.json`.
3. **Android Application Record**: `com.meditag.app`.

Locking:
- The tag gets a 32-bit write password (PWD/PACK) and AUTH0 = page 4, so writes need the password but reads stay open.
- The password is generated per tag by the server and stored encrypted (AES-256-GCM).
- `tagId` is a random 16-character base64url string. It is never personal data.

## Platforms (all kept in sync through one backend)

- **Website** (Next.js, a PWA). Everyone can use it with no install. It has:
  - the public **Scan a MediTag** page (Web NFC works only on Android Chrome)
  - the public `/e/<tagId>` emergency page
  - citizen login, dashboard and profile editor
  - (to come) records, doctor and admin areas
- **Android app** (Flutter): scanning (offline signature check) and **programming/updating tags**. Tags are programmed only from the app, because browsers can't set the tag password.
- **iPhone:** reads tags natively by opening the URL in Safari (needs internet). An iOS app needs a Mac with Xcode to build.

## Hard constraints and decisions

- **Free tier only, no credit card:**
  - Firebase **Spark**: Auth + Firestore
  - **Vercel Hobby**: the website plus server logic as Next.js API routes, using the Firebase Admin SDK
  - **Supabase free**: a private Storage bucket for medical files
  - No Cloud Functions and no Firebase Storage, because both need the paid Blaze plan.
- **Security:**
  - Signed tag payloads, password-locked tags, proof-of-presence doctor access.
  - Audit logs and patient notifications.
  - Firestore rules: clients touch only their own data; all writes that grant access or touch tags go through the API routes.
- **Privacy:** DPDP Act 2023. Explicit consent, the right to download and delete data, and sensitive conditions are cloud-only by default.
- **Design:**
  - **Light mode only.**
  - Periwinkle background (`#E8ECFB`), navy primary (`#171A2E`), pastel accents (mint, rose, peach, sky, lavender) used flat. **No gradients.** Soft glows and shadows are only on floating cards.
  - Heavy, tightly spaced headings (Plus Jakarta Sans 800) with Inter for body text.
  - **No outside photos or images.** Illustrations are drawn in code, such as the tilted emergency-profile card on the home and login pages.
  - Design tokens live in `design/tokens.json`, and `node design/build-tokens.mjs` generates the CSS and Dart versions.

## Definition of done (the whole project)

1. A citizen signs up on web or app, fills in their profile, and uploads records.
2. The citizen programs up to 3 real NTAG216 tags from the Android app. The tags are locked and appear on the dashboard.
3. A bystander taps a tag with any phone and gets the emergency card. Offline and verified with the Android app; online via the URL on iPhone or without the app. They can call family, call 108/112, or send their location.
4. A doctor signs up, an admin approves them, and the doctor taps a tag to get 24 h full history. The patient is notified, and every view is in their access log.
5. A lost tag is revoked from web or app and stops working immediately.
6. Everything is deployed on free tiers, tested on real hardware, and demo-ready.
