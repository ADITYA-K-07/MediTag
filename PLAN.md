# MediTag — Project Plan

> An NFC tag that carries a person's emergency medical info offline, plus a secure link to their full medical history in the cloud. Available as a **mobile app and a website**, kept in sync, with a **public "Scan a Tag" button** anyone can use at an accident scene.

---

## 1. Problem & Solution (one paragraph for the report)

When an unidentified accident victim reaches a hospital, doctors operate blind: no name, no blood group, no allergy list, no emergency contact, no history. MediTag gives every citizen up to **3 NTAG216 NFC tags** (car sticker, wallet card, wearable). A doctor taps a phone on any tag and gets:

1. **Tier 1 – Emergency info (offline, on the tag):** name, blood group, allergies, critical conditions, current medicines, emergency contact. Readable in about a second, even with no internet, **by anyone**, including a bystander at the roadside who wants to call the victim's family.
2. **Tier 2 – Full medical history (online, in the cloud):** past surgeries, reports, prescriptions, scans. Only **verified doctors** can open it, and every access is logged and reported to the patient.

Users can choose the **Android/iOS app** or the **website** (no install needed). Both use the same accounts and data, so changes show up in both straight away.

---

## 2. System Architecture

```
                    ┌─────────────────┐
                    │  NTAG216 tag    │
                    │  - URL record   │
                    │  - signed basic │
                    │    info record  │
                    │  - write-locked │
                    └───┬─────────┬───┘
                NFC tap │         │ NFC tap / QR
          ┌─────────────▼──┐   ┌──▼──────────────────────┐
          │ Mobile app     │   │ Website (PWA)           │
          │ Flutter        │   │ Next.js + Web NFC       │
          │ Citizen/Doctor/│   │ Citizen/Doctor/         │
          │ "Scan a Tag"   │   │ "Scan a Tag"            │
          └───────┬────────┘   └────────┬────────────────┘
                  │  HTTPS + Firebase ID token (JWT)
                  └──────────┬──────────┘
                             ▼
          ┌──────────────────────────────────────┐
          │ Shared backend (one Firebase project)│
          │  ├─ Auth (Phone OTP, email + 2FA)    │
          │  ├─ Cloud Functions (signing, tag    │
          │  │   passwords, access grants, audit)│
          │  ├─ Firestore (real-time sync)       │
          │  ├─ Cloud Storage (PDFs, scans)      │
          │  └─ FCM (push + web push)            │
          └──────────────────────────────────────┘
                             │
          ┌──────────────────┴───────────────────┐
          │ Admin panel (route inside the website)│
          └──────────────────────────────────────┘
```

### Recommended tech stack

| Layer | Choice | Why |
|---|---|---|
| Mobile app | **Flutter** + `nfc_manager` | One codebase for Android + iOS, full NFC control (incl. tag password) |
| Website | **Next.js (React) + Tailwind CSS**, installable **PWA** | Loads fast, which matters on the public emergency page. Direct access to the Web NFC API. Works offline after first visit. |
| Hosting | Firebase Hosting (or Vercel) | Same project as the backend |
| Auth | **Firebase Authentication** (phone OTP, email/password + TOTP 2FA) + custom claims for roles | Same login on app and web |
| Database | **Cloud Firestore** | Real-time listeners keep app and web in sync automatically |
| File storage | **Firebase Cloud Storage** | Accessed only through short-lived signed URLs |
| Server logic | **Cloud Functions (TypeScript)** | The one place that signs tag data and grants access |
| Notifications | **Firebase Cloud Messaging** | Push on the app, Web Push in the browser |
| Device security | App: `flutter_secure_storage` + `local_auth`. Web: **WebAuthn passkeys** (fingerprint/Face ID in the browser) | Re-auth before sensitive actions on both platforms |

**Why not Flutter Web for the site?** Flutter Web's first download is ~2 MB+, so it loads slowly on a weak 3G signal at an accident scene. Next.js serves a ~100 KB emergency page. You'll write the UI twice, but both use the **same design tokens** (Section 6) and the **same backend**, so they look and behave alike.

---

## 3. App ↔ Website Sync & Feature Parity

### 3.1 How sync works
- **One source of truth:** both clients read and write the same Firestore documents. Neither keeps its own database.
- **Real-time:** both use Firestore `onSnapshot` listeners. Add an allergy on the website and the app's profile screen updates within a second.
- **Offline edits:** Firestore offline persistence is on in both (IndexedDB on web). Edits made offline queue up and sync when you reconnect. If two edits clash, the last write wins, using a server timestamp `updatedAt`.
- **Same session rules:** logging out from "Active devices" in Settings ends the session on every device (revokes refresh tokens).
- **Shared contracts:** one `schema/` folder in the repo holds JSON Schemas for the profile, records and tag payload. Dart and TypeScript models are generated from these schemas, so the app and website never disagree on a field.
- **Tag data is never built on the client.** Both clients ask the same Cloud Function for the signed payload, so a tag written from the app or the website is byte-for-byte the same.

### 3.2 Feature matrix

| Feature | Android app | iOS app | Website – Android Chrome | Website – iPhone / Desktop |
|---|---|---|---|---|
| Sign up / login / edit profile | ✅ | ✅ | ✅ | ✅ |
| Upload medical records | ✅ | ✅ | ✅ | ✅ |
| Access log, notifications | ✅ | ✅ | ✅ (Web Push) | ✅ (Web Push, iOS 16.4+ when installed as PWA) |
| **Scan a Tag (offline)** | ✅ | ✅ | ✅ Web NFC | ⚠ iPhone: tap opens the URL natively (needs internet). Desktop: QR only |
| **Program / lock a tag** | ✅ | ✅ | ❌ see note | ❌ |
| Doctor full-history view | ✅ | ✅ | ✅ | ✅ (via "Recent patients", see 5.3) |
| Admin panel | — | — | ✅ | ✅ |

**Why can't the website program tags?** Web NFC can write NDEF records, but it **can't send the low-level NTAG216 commands** that set the write password. A tag written from a browser would stay unlocked and anyone could overwrite it. So the website shows **"Program tags in the MediTag app"** with a QR code to install it. Web-only users can still order a **pre-programmed tag** or print a **QR wallet card** (Section 4.3).

**Why does iPhone need internet?** iPhones read the tag's URL record without any app: hold the top of the phone to the tag and a banner opens the website. Safari has no Web NFC, though, so the offline record can't be read from the browser. On iPhone, offline reading needs the app.

---

## 4. What Goes on the Tag (NTAG216 memory design)

### 4.1 NDEF records
The NTAG216 has **888 bytes** of user memory. The tag holds one NDEF message with 3 records:

| # | Record type | Content | Approx size |
|---|---|---|---|
| 1 | **URI** (must be first) | `https://meditag.app/e/<tagId>`, where tagId is a random 16-char token (**never** Aadhaar or phone number) | ~40 B |
| 2 | **MIME** `application/vnd.meditag.v1` | Compact emergency data (minified JSON) + **digital signature** | ~350–550 B |
| 3 | **Android Application Record** | `com.meditag.app`. If the app is installed it opens; if not, Android opens the URL in the browser. | ~20 B |

The URL record comes first so that **any phone with no app at all** still opens the public emergency page in the browser. This one choice is what makes the website work as a full alternative to the app.

Example of the emergency payload (minified JSON, ~300 B before signing):

```json
{"v":1,"n":"Rahul Sharma","dob":"1998-04-12","bg":"B+",
 "al":["Penicillin","Peanuts"],"cc":["Type 1 Diabetes"],
 "med":["Insulin glargine 20u"],"org":"Y",
 "ec":[{"n":"Priya Sharma","r":"Mother","p":"+919876543210"}],
 "tid":"k8Fq2xLm9Pz4Rt7W","ts":1761900000}
```

…plus a 64-byte **ECDSA P-256 signature** created by the server.

### 4.2 Why the signature matters
Anyone with a ₹500 NFC app can write *something* onto a blank tag. The signature lets both the app and the website check, **even offline**, that the data came from MediTag and hasn't been changed. Both clients ship with the server's public key, and any edited or fake tag shows as **"⚠ Unverified — this info may not be genuine"**.

### 4.3 QR fallback
Every tag comes with a matching **QR code** pointing to the same `/e/<tagId>` URL. You can print it on the wallet card or download it as a PDF from the website. It covers desktops, phones without NFC and web-only users. A QR scan needs internet.

---

## 5. User Roles & Flows

MediTag has **four** kinds of user. Three log in. One doesn't:

| Role | Login? | Sees |
|---|---|---|
| **Bystander / Public** | ❌ No login | Tier 1 emergency info only |
| **Citizen** | ✅ | Own data, manages own tags |
| **Doctor** (verified) | ✅ + 2FA | Tier 1 + Tier 2 after tapping the tag |
| **Admin** | ✅ + 2FA | Verification and moderation tools |

### 5.1 Bystander — "Scan a MediTag" (no login)

The headline feature. A **"Scan a MediTag" button** is the **most visible thing on the app's first screen and on the website's home page**, above the Login button, and it works without an account.

**Flow (e.g., an accident happens in front of you on the road):**
1. Open the MediTag app **or** go to `meditag.app` → tap **"Scan a MediTag"**.
   - *No app installed and no website open?* Just hold your phone to the tag. Android and iPhone both open the emergency page automatically from the URL record.
2. A scan sheet appears with a pulsing glow ring: *"Hold the back of your phone near the tag"*. A help card shows the usual places a tag might be: wallet, keychain, bracelet, car dashboard or windscreen.
3. Tag read → **Emergency card** shows instantly. It's read straight from the tag, so it **works offline**:
   - Name, age, blood group (very large)
   - Allergies and critical conditions (highlighted)
   - Current medicines
   - **📞 Call [Mother – Priya]** big button for each emergency contact
   - **🚑 Call 108 (Ambulance)** and **🆘 Call 112** buttons
   - Verification badge: ✅ *Verified MediTag* / ⚠ *Unverified*
   - "Last updated 2 months ago"
4. **"Send my location to family"** button:
   - **Online:** sends a push + SMS to the emergency contacts: *"Rahul's MediTag was scanned at [Google Maps link] at 4:12 PM. The person who scanned it may call you."*
   - **Offline:** opens the phone's SMS app with that same message and GPS coordinates already filled in. SMS works without mobile data, which matters on village roads.
5. Bystander guidance panel: *"Don't move the person if you suspect a spinal injury. Stay on the line with 108."* (short, static first-aid tips)
6. If online, the scan is logged anonymously (time, approximate location) and the citizen sees it in their access log.

**What the bystander can NOT see:** medical history, reports, scans, doctor notes. There is no "View full history" button for them, only *"Are you a doctor? Log in for full history"*.

**Abuse protection on the public page:**
- tagIds are random 96-bit tokens, so nobody can guess them
- The public `/e/<tagId>` endpoint is rate-limited per IP (e.g., 20/min) and protected with Firebase App Check
- The page sends `noindex`, so search engines never list it
- "Send location" is limited to 3 messages per tag per hour

### 5.2 Citizen

**Registration (app or website, same account)**
1. Enter mobile number → OTP verify
2. Basic KYC: name, DOB, gender, photo (optional: link ABHA ID)
3. Set up re-auth: fingerprint/PIN in the app, **passkey** on the website
4. Accept consent screen (DPDP)

**Manage medical profile (app or website)**
- Emergency info form (blood group, allergies, conditions, medicines, emergency contacts, organ donor)
- Toggle per field: *"On tag – visible to anyone who scans"* vs *"Cloud only – doctors only"*. A live preview shows exactly what a bystander will see.
- Medical history: add entries (surgery, diagnosis, prescription, lab report) with PDF/image upload. The website is handier here: drag-and-drop from a laptop.
- **Access log**: *"Dr. A. Mehta, AIIMS Delhi viewed your record · 31 Oct, 14:02"* / *"Anonymous scan near Pune · 31 Oct, 16:12"*
- **"Tags need updating"** banner: shows when the profile has changed since the tags were last written

**Program a tag (app only, strongly authenticated)**
1. Tap "Program new tag" → **biometric prompt**
2. App asks the server for: signed payload + new tagId + per-tag password. The Cloud Function checks the user is logged in, has fewer than 3 active tags, and isn't over the rate limit.
3. User holds the tag to the phone
4. App: verifies the chip is a real NTAG216 (NXP originality signature) → writes NDEF → sets PWD/PACK → enables write protection from page 4 onward (reads stay open)
5. App reads the tag back and checks it → tells the server "tag activated"
6. Tag appears under **My Tags** (Car / Wallet / Bracelet) on **both app and website**, with Revoke and Download QR options

**Update a tag:** same flow, but the app gets the existing tag's password from the server to unlock it first.

**Revoke a tag:** works from the app or the website, e.g., log in from a friend's laptop right after losing your wallet.

### 5.3 Doctor

**Registration (app or website)**
1. Email + password + phone OTP + TOTP authenticator (2FA)
2. Enter: Medical Council registration no., council name, hospital, upload license/ID photo
3. Status = `pending`. Until approved, they get only the same Tier 1 view as a bystander.
4. Admin approves → role claim `doctor_verified` set → doctor gets a notification

**Emergency read**
1. Tap the tag with the app or the website on an Android phone (same "Scan a MediTag" button; when logged in as a doctor it shows extra options)
2. **Instant offline Emergency card** (same as bystander)
3. If online + verified → **"View full medical history"** button
4. Server checks: doctor verified, tag active, tag tapped in the last 10 min (client sends tagId + tap timestamp + NFC UID) → creates an **access grant valid 24 h** → logs it → notifies the patient
5. Doctor sees a timeline of history + documents (signed URLs)
6. (Optional) Doctor adds a **clinical note** (*"Admitted for head trauma, 31 Oct"*). It's tagged as doctor-written and read-only for the patient.

**Phone-to-desktop handoff (sync in action):** hospital desktops have no NFC. After a doctor taps the tag on their phone, the patient appears under **"Recent patients (24 h)"** on the doctor's **website dashboard**, so they can read reports on a big screen. The same grant is behind both views, so the website gives no extra access.

### 5.4 Admin (website only, `/admin`)
- Approve or reject doctor applications (side-by-side view of license and registry details)
- Revoke tags / suspend accounts
- View audit logs, rate-limit alerts

---

## 6. UI/UX Design System

The goal is calm, clean and trustworthy, like a modern health product. Pastel surfaces, soft glows, **no gradients**, lots of white space, one clear action per screen. **The app and website share one set of design tokens** (`design/tokens.json`). These export to a Tailwind theme for the website and a Dart `ThemeData` for the app, so both look identical.

### 6.1 Colour palette (pastel + one strong ink colour per hue for text and contrast)

| Token | Pastel (surfaces, chips) | Strong (text, icons, CTA) | Used for |
|---|---|---|---|
| `mint` | `#D6F5E8` | `#1F7A5C` | **Primary / Citizen**, success, "Verified" |
| `lavender` | `#E6E1FA` | `#5B4BB7` | **Doctor** role, links |
| `rose` | `#FCE1E4` | `#B4233C` | **Emergency**, allergies, Scan button, Call buttons |
| `peach` | `#FFE8D6` | `#A65A1C` | Warnings, "Unverified", "Tag needs update" |
| `sky` | `#DCEEFF` | `#2563A8` | Info, offline indicator |
| `neutral-bg` | `#FAFAF8` | — | App background (warm off-white) |
| `surface` | `#FFFFFF` | — | Cards |
| `ink` | — | `#1C2430` | Primary text |
| `ink-muted` | — | `#667085` | Secondary text |
| `line` | `#ECEDEF` | — | 1px borders and dividers |

**Rules:**
- **No gradients anywhere.** Every fill is one flat colour.
- Pastel colours are **backgrounds only**. Text on them always uses the matching *strong* colour or `ink`, which keeps contrast at WCAG AA (≥ 4.5:1).
- Each role has one colour (mint = citizen, lavender = doctor, rose = emergency), so users always know which "mode" they're in.
- **Dark mode:** background `#12161C`, cards `#1A2029`, pastel colours turn into 12% tints of the strong colours, and glows get slightly stronger.

### 6.2 Glows (instead of gradients and heavy shadows)
Soft, coloured light around an element, never a black drop-shadow:

```css
--glow-mint:  0 0 0 4px rgba(31,122,92,.12), 0 8px 24px rgba(31,122,92,.14);
--glow-rose:  0 0 0 6px rgba(180,35,60,.12), 0 10px 32px rgba(180,35,60,.18);
--glow-focus: 0 0 0 3px rgba(91,75,183,.35);          /* keyboard focus ring */
--shadow-card: 0 1px 2px rgba(28,36,48,.04), 0 4px 16px rgba(28,36,48,.05);
```
- **Primary buttons:** glow appears on hover/press
- **Scan button:** a rose glow ring gently **pulses** (scale 1 → 1.06, opacity .5 → 0, 1.8 s loop) to say "tap me"
- **Scanning sheet:** expanding concentric rings in flat rose at falling opacity. No gradient.
- **Verified badge:** faint mint glow
- **Focus states:** lavender ring, so keyboard users can always see where they are

### 6.3 Typography
- Font: **Plus Jakarta Sans** (headings) + **Inter** (body). Both free on Google Fonts and good with Indian names.
- Scale: 32 / 24 / 20 / 16 (body) / 14 / 12
- **Emergency card exception:** blood group at **56 px bold**, name at 28 px, body at 18 px, so it's readable in sunlight and by panicking people
- Ready for Hindi + regional scripts later: Noto Sans Devanagari as fallback

### 6.4 Shape, spacing, motion
- Corner radius: **16 px** for cards, **12 px** for inputs, **full pill** for primary buttons and chips
- 8-pt spacing grid. Cards have 20–24 px padding.
- Touch targets ≥ **48 px**. Emergency call buttons ≥ **64 px** tall and full width.
- Motion: 150–250 ms, `cubic-bezier(.2,.8,.2,1)`. Screens slide in, cards fade up 8 px, toggles spring slightly.
- `prefers-reduced-motion` respected: pulses and slides turn into simple fades
- Icons: **Lucide** (one stroke weight, rounded). Same set on web and app.

### 6.5 Key screens — visual intent

**Home (logged out) – app & website**
```
┌────────────────────────────────────┐
│ MediTag                    Log in  │
│                                    │
│   Medical info that speaks         │
│   when you can't.                  │
│                                    │
│      ╭──────────────────────╮      │
│      │  ◉  Scan a MediTag   │ ← rose pill, pulsing glow
│      ╰──────────────────────╯      │
│   Saw an accident? Scan their tag  │
│   to reach their family.           │
│                                    │
│  [ I'm a Citizen ]  [ I'm a Doctor ]│ ← mint / lavender outline
└────────────────────────────────────┘
```

**Emergency card (after scan)**
```
┌────────────────────────────────────┐
│ ✅ Verified MediTag · Offline       │ ← mint chip / sky chip
│                                    │
│  Rahul Sharma · 28 y · Male        │
│  ┌──────┐                          │
│  │  B+  │  Blood group             │ ← rose pastel tile, 56px
│  └──────┘                          │
│  ⚠ Allergies: Penicillin, Peanuts  │ ← rose pastel card
│  ♥ Type 1 Diabetes · Insulin       │
│                                    │
│ ╭────────────────────────────────╮ │
│ │ 📞 Call Mother – Priya          │ │ ← full-width, rose strong
│ ╰────────────────────────────────╯ │
│ [🚑 Call 108]        [🆘 Call 112] │
│ [📍 Send my location to family ]   │
│                                    │
│  Are you a doctor? Log in →        │
└────────────────────────────────────┘
```

**Citizen dashboard:** profile completeness ring (flat mint arc), "My Tags" cards with a status dot, "Tags need updating" peach banner, recent access log.

**Doctor dashboard:** lavender accents, "Scan patient tag" main action, "Recent patients (24 h)" list.

### 6.6 UX principles
1. **Emergency first:** the Scan button needs no login, no splash delay and no cookie banner, and loads in under 1 s
2. **One primary action per screen**
3. **Always show state:** Offline / Online, Verified / Unverified, Last updated, which tags are out of date
4. **Explain privacy where it happens:** the "visible to anyone" toggle shows a live preview of the bystander view
5. **Skeleton loaders**, not spinners. Optimistic updates for edits.
6. **Accessibility:** WCAG AA contrast, screen-reader labels, works at 200% text size
7. **Responsive website:** mobile-first. On desktop the dashboard becomes a two-column layout with a side nav.

---

## 7. Security Design

### 7.1 Threats and countermeasures

| Threat | Countermeasure |
|---|---|
| Stranger overwrites tag data | **NTAG216 PWD/PACK write protection**: a 32-bit password locks writes. The password is generated per tag by the server and never shown to the user. Tags are programmed in the app only. |
| Someone edits data on a tag anyway / clones tag | **Server-signed payload** (ECDSA), checked offline by the app and website. NXP originality signature checked at programming time. |
| Someone else logs in as the citizen | Phone OTP + **biometric (app) / passkey (web) re-auth** before any edit, tag action or record download. "Active devices" list with remote logout. |
| Fake doctor | Account locked until an admin checks the NMC/State Medical Council registration number and license. Real-world version: **ABDM Healthcare Professional Registry**. Doctor login needs TOTP 2FA. |
| Doctor snooping on random people | Full history opens only after **a physical tap on the tag**. Every access is logged and the patient is notified. Grants expire after 24 h. |
| Scraping the public emergency page | Random 96-bit tagIds, per-IP rate limits, Firebase App Check, `noindex` |
| Spamming family via "Send location" | 3 per tag per hour, plus App Check |
| Lost / stolen tag | **Revoke a tagId** from the app or website. The cloud link stops working and scanners see "This tag has been deactivated". |
| Web-specific attacks (XSS, CSRF, session theft) | Strict Content-Security-Policy, HttpOnly secure cookies for SSR pages, React's auto-escaping, no third-party scripts on emergency/medical pages |
| Data breach on server | TLS everywhere, Firestore security rules, files encrypted at rest, signed URLs valid for 5 min, no Aadhaar stored |
| Stale info on tag | Payload timestamp + "Last updated" label + "Tags need updating" banner |

### 7.2 Privacy trade-off (be upfront about this in the report)
Tier-1 data is **readable by anyone who taps the tag**. That's deliberate: a bystander or a village nurse with no internet must be able to read it. So Tier 1 holds only what's needed to save a life, and **citizens choose each field** with a live preview of what bystanders see. Sensitive conditions (HIV status, psychiatric history) default to *cloud only*.

### 7.3 Compliance
- **Digital Personal Data Protection Act, 2023 (DPDP):** explicit consent at signup, right to download and delete all data (one button in Settings, app and web), purpose limitation
- **ABDM / ABHA ID** as a future integration path

---

## 8. Data Model (Firestore)

```
users/{uid}
  role: "citizen" | "doctor" | "admin"
  phone, name, dob, gender, photoRef?, abhaId?, createdAt

emergencyProfiles/{uid}
  bloodGroup, allergies[], conditions[], medications[],
  emergencyContacts[{name, relation, phone}], organDonor,
  onTagFields: {allergies: true, conditions: false, ...}
  updatedAt                     ← compared with tags.writtenAt for "needs update"

medicalRecords/{uid}/entries/{entryId}
  type: "surgery" | "diagnosis" | "prescription" | "lab" | "imaging" | "note"
  title, date, hospital, description, fileRefs[],
  authorType: "citizen" | "doctor", authorId, updatedAt

tags/{tagId}
  ownerUid, label: "Car" | "Wallet" | "Bracelet",
  nfcUid, status: "active" | "revoked",
  encryptedPwd (server-only), payloadVersion, writtenAt

doctors/{uid}
  regNo, council, hospital, licenseFileRef,
  status: "pending" | "verified" | "rejected", verifiedBy, verifiedAt

accessGrants/{grantId}
  doctorUid, patientUid, tagId, grantedAt, expiresAt

publicScans/{scanId}           (written only by Cloud Functions)
  tagId, approxLocation?, scannedAt, locationShared: bool

devices/{uid}/sessions/{sessionId}
  platform: "android" | "ios" | "web", userAgent, lastSeen, fcmToken

auditLogs/{logId}             (append-only, written only by Cloud Functions)
  actorUid | "anonymous", action, targetUid, tagId, platform, timestamp
```

**Security rule summary:**
- Citizens can read/write only their own `emergencyProfiles` and `medicalRecords`
- Doctors can read `medicalRecords/{uid}` **only if** a valid, unexpired `accessGrants` doc exists
- `tags`, `accessGrants`, `publicScans`, `auditLogs` are written **only** by Cloud Functions
- The same rules protect app and web, because both talk to the same Firestore

---

## 9. Backend API (Cloud Functions)

| Function | Caller | Purpose |
|---|---|---|
| `prepareTagWrite(label)` | Citizen (app) | Checks limit (≤3), makes tagId + password, signs payload |
| `confirmTagWrite(tagId, nfcUid)` | Citizen (app) | Marks tag active, logs it |
| `prepareTagUpdate(tagId)` | Citizen (app) | Returns current password + new signed payload |
| `revokeTag(tagId)` | Citizen (app/web) | Revokes tag |
| `getTagQr(tagId)` | Citizen (app/web) | Returns printable QR wallet-card PDF |
| `publicEmergencyView(tagId)` | Anyone | Returns Tier 1 info only (for URL/QR opens when the tag itself wasn't read) |
| `notifyEmergencyContacts(tagId, lat, lng)` | Anyone | Sends push + SMS with location (rate-limited) |
| `requestPatientAccess(tagId, nfcUid, tapTs)` | Verified doctor | Checks tap, creates 24 h grant, logs it, notifies patient |
| `listRecentPatients()` | Verified doctor (web) | Active grants, for the desktop handoff |
| `getFileUrl(entryId, fileId)` | Owner / granted doctor | Returns 5-min signed URL |
| `approveDoctor(uid)` | Admin | Sets `doctor_verified` claim |
| `exportMyData()` / `deleteMyAccount()` | Citizen | DPDP rights |

---

## 10. Screens

| Area | Mobile app | Website |
|---|---|---|
| **Public** | Home with **Scan a MediTag** · Scan sheet · Emergency card · Send location · First-aid tips | `/` Home with **Scan a MediTag** · `/scan` · `/e/[tagId]` Emergency card · About / How it works · Order tags |
| **Auth** | Role select → Login/Register → OTP → Biometric setup | Same, with passkey setup |
| **Citizen** | Dashboard · Emergency Profile editor (with bystander preview) · Medical History · Add Record · **My Tags (program / update / revoke)** · Access Log · Settings | Dashboard · Profile editor · Medical History (drag-and-drop upload) · My Tags (**revoke, download QR**; "Program in app" prompt) · Access Log · Settings / Active devices |
| **Doctor** | Verification status · Scan patient · Emergency card · Full history · Add note · My access history | Verification status · Scan (Android Chrome) · **Recent patients (24 h)** · Full history (big-screen layout) · Add note |
| **Admin** | — | `/admin`: Pending doctors · Doctor detail · Users & tags · Audit logs |

---

## 11. Repository Layout

```
meditag/
├─ app/          Flutter mobile app
├─ web/          Next.js website (PWA)
├─ functions/    Firebase Cloud Functions (TypeScript)
├─ schema/       JSON Schemas → generated Dart + TS models
├─ design/       tokens.json → Tailwind theme + Flutter ThemeData
├─ firestore.rules, storage.rules
└─ PLAN.md
```

---

## 12. Development Timeline (≈ 14 weeks)

| Week | Milestone |
|---|---|
| 1 | Requirements, SRS, **design tokens + Figma mockups** (home, scan, emergency card, dashboards), buy NTAG216 tags |
| 2 | Monorepo setup: Flutter app, Next.js site, Firebase project, shared `schema/` + `design/` pipelines |
| 3 | Auth on both platforms (phone OTP, roles, biometric/passkey) |
| 4 | **NFC spike**: read/write NDEF on NTAG216 in Flutter, test PWD/PACK lock; Web NFC read on Android Chrome |
| 5 | Emergency profile editor (app + web) with real-time sync + Firestore rules |
| 6 | Payload signing Cloud Function + offline signature check (Dart + TS) |
| 7 | **Public Scan a MediTag flow** on app + web: emergency card, call buttons, send location (online + SMS fallback), `/e/[tagId]` page |
| 8 | Full tag programming flow in app, My Tags on both, revoke, QR wallet card |
| 9 | Medical history CRUD + file upload (app + web) |
| 10 | Doctor registration + admin panel |
| 11 | Doctor tap → access grant → full history; desktop "Recent patients" handoff |
| 12 | Audit logs, notifications (FCM + Web Push), PWA offline caching, dark mode |
| 13 | Testing (Section 13), Lighthouse + accessibility audit, UI polish & micro-animations |
| 14 | Report, demo video, presentation |

---

## 13. Testing Plan (show these in your demo)

1. **Offline read (app):** airplane mode → tap tag → emergency card appears within about 1 s
2. **Offline read (website):** visit the site once, go offline, open the installed PWA on Android Chrome → Scan → card appears
3. **No-app read:** phone with nothing installed taps the tag → browser opens the emergency page
4. **Bystander call flow:** Scan → "Call Mother" opens the dialer with the right number. "Send location" while offline opens SMS with coordinates filled in.
5. **Tamper test:** change blood group with a generic NFC app → app and website both show "Unverified"
6. **Write-protection test:** try overwriting with a generic NFC app → write is refused
7. **Sync test:** edit an allergy on the website → app updates within 1 s without a refresh. Do it offline too → syncs on reconnect.
8. **Unauthorized doctor:** pending doctor scans → Tier 1 only
9. **No-tap access:** verified doctor calls the API with a guessed tagId → denied
10. **Desktop handoff:** doctor taps on phone → patient shows in website "Recent patients"
11. **Revocation from web:** revoke on laptop → app scan shows "Tag deactivated"
12. **Audit:** doctor view and anonymous scan both appear in the citizen's access log with notifications
13. **Rate limit:** 25 rapid requests to `/e/<tagId>` → throttled
14. **UI quality:** Lighthouse ≥ 90 (Performance, Accessibility) on `/` and `/e/[tagId]`. Contrast checks pass in light and dark mode.

---

## 14. Known Limitations (put in report; examiners like honesty)

- NTAG216's 32-bit password is weak against a determined attacker. The **signature** is the real integrity guarantee.
- Tier-1 data is public by design. Reduce the risk with per-field choice and a live preview.
- **Web NFC works only in Chrome on Android.** iPhone Safari and desktops use the tag's URL or QR, which needs internet. Offline iPhone reads need the app.
- Tags can only be programmed in the app, because browsers can't set the NTAG password.
- Emergency contact numbers are visible to anyone who scans. Future option: masked "Call via MediTag" relay numbers.
- Proof-of-presence only shows *a* phone tapped the tag. Logging and notifications discourage misuse.
- Doctor verification is manual in this prototype.

## 15. Future Scope
- ABHA / ABDM health-locker integration
- Masked calling for emergency contacts
- Hospital dashboard / multi-doctor teams
- Multilingual UI (Hindi + regional languages)
- Smartwatch integration, crash detection that pushes the MediTag info to contacts automatically

---

## 16. Shopping List
- 10× NTAG216 tags (stickers + cards + key-fob/wristband): ~₹30–60 each
- Anti-metal NTAG216 sticker for the car (normal tags don't work on metal surfaces)
- 1–2 Android phones with NFC (and an iPhone if available, for the URL-open test)
- Firebase Blaze plan (pay-as-you-go, free at this usage) for Cloud Functions + SMS. Domain name ~₹800/yr (optional; Firebase gives a free `*.web.app` URL).
