# MediTag: what to do next

> Handoff doc 3 of 3. Goal: `1-GOAL.md`. Current state: `2-BUILT.md`.
> Overall about 45% done. The foundations (security, login, database, website, tag format) are complete.
> What's left is mostly screens and flows built on top of them, plus testing on real hardware.

## About the user, and how to work with them

- Engineering course project. The user is on **Windows**, owns an **iPhone**, and will **borrow an Android phone** with NFC to program tags.
- **Free tier only.** Never suggest paid plans (Firebase Blaze, Apple Developer and so on) without saying so clearly.
- The user does account and console steps themselves. Give exact click-paths. **Never ask for secrets in chat**; the only values to ask for back are public ones (IDs, public key, URLs).
- Commit on a feature branch, push, and give a **pre-filled GitHub compare link** (`gh` isn't installed). The user merges, and Vercel deploys `main`.
- Design taste: the home page's style is the reference.
  - Light only, periwinkle and navy, pastel accents, no gradients, no outside photos.
  - A drawn, tilted card illustration and subtle motion.
- The user prefers short, plain explanations and wants the work verified, not assumed.

## Immediate (to finish what's in flight)

1. **User:** add the debug SHA-1 and SHA-256 fingerprints (listed in `2-BUILT.md`) to the Firebase Android app `com.meditag.app`.
2. **Real-hardware test:**
   1. Install `app-debug.apk` on the Android phone.
   2. Log in with `9999900001` / `123456`.
   3. Program an NTAG216 and check it appears on the web dashboard.
   4. Tap it with the iPhone (it should open `/e/<id>` with data) and with the app (it should show **Verified** offline).
   5. Revoke it on the web, then check the scan shows "deactivated".
   6. Fix whatever real hardware reveals. Likely suspects: the NfcA timeout, the ACK/NAK handling in `ntag216.dart`, and Play Integrity on login.

## Next features, in recommended order

### A. Medical history (website first, then the app)
- `/citizen/records`: a timeline of entries (`medicalRecords/{uid}/entries`, with type, title, date, hospital and notes).
- File upload: `POST /api/files/upload` returns a signed URL; upload to Supabase, then store the `path` in the entry's `fileRefs`. View files through `POST /api/files/download`.
- Add it to the dashboard nav, and show the record count on the dashboard.

### B. Doctor flow
- Enable **Email/Password** sign-in in Firebase (the user does this in the console).
- **Doctor sign-up page:** name, Medical Council registration number, council, hospital, and a licence upload (Supabase `doctorDocs/{uid}/…`). Create `doctors/{uid}` with status pending.
- **Doctor dashboard** (web): "Recent patients (24 h)" from `accessGrants` where `doctorUid == me`, and a full-history view with notes. Use the mockups in `design/mockups/DoctorWeb.dc.html` and `DoctorApp.dc.html`.
- **App doctor mode:** tap a tag → call `POST /api/access {tagId, nfcUid, tappedAt}` → show the full history. The patient gets a notification; the server already does this.

### C. Admin
- Create the first admin by setting the custom claim `{role: "admin"}` with a one-off Admin SDK script, run by the user locally.
- `/admin`: a queue of pending doctors, with the licence (download link) and Approve or Reject with a reason via `POST /api/admin/doctors/:uid/review`, plus an audit log. Mockup: `design/mockups/AdminWeb.dc.html`.
- After a doctor is approved, they must log out and back in (or refresh their ID token) to pick up the new claims.

### D. Citizen extras
- An access log page (doctor views and anonymous scans from `publicScans` and `auditLogs`).
- A QR wallet card PDF, pointing to the same `/e/<tagId>`.
- Settings: download my data and delete my account (DPDP).
- The app's emergency card: add GPS to "Send my location" (needs the geolocator package and a permission).

### E. Hardening before the demo
- reCAPTCHA Enterprise for Firebase Auth (free up to 10k a month) to stop image challenges.
- Rate-limit `/e/[tagId]` and the API. Vercel KV/Upstash have free tiers, or use a simple Firestore counter.
- Firebase App Check (optional).
- A release APK (signed). Its SHA fingerprint must also be added to Firebase.
- Update `README.md` and `SETUP.md` to match the final state.

### F. Optional
- An iPhone app: only with access to a Mac and Xcode. The Flutter code is mostly ready; writing tags on iOS would need `MiFareIos.sendMiFareCommand` in `tag_session.dart`.
- Push notifications (FCM). Notifications currently show in-app from Firestore only.

## Prompt to start the new chat

> I'm continuing the MediTag project (repo `D:\MediTag`). Read `docs/handoff/1-GOAL.md`, `2-BUILT.md` and
> `3-NEXT.md` first, then `web/AGENTS.md` before touching Next.js code. Then start with the "Immediate"
> list in `3-NEXT.md`.
