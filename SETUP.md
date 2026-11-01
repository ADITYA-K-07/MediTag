# MediTag setup: free tier only

Everything here is free with no credit card:

| Service | Plan | Used for |
|---|---|---|
| Firebase | **Spark** (free) | Login (Auth) and database (Firestore) |
| Vercel | **Hobby** (free) | Hosts the website, plus the server logic as API routes (tag signing, doctor access) |
| Supabase | **Free** | Private file storage for medical reports (1 GB) |

> **Keep secrets private.** Lines marked 🔒 are secrets. Put them only in `web/.env.local` (git ignores it) and in Vercel's Environment Variables. Never in chat, never in git. Only the values marked ✅ need to come back to Claude.

---

## 1. Firebase (Spark plan, don't upgrade)

1. Go to https://console.firebase.google.com → **Add project** → name it `meditag` → you can turn Google Analytics off.
   - ✅ Note the **Project ID**, e.g. `meditag-1a2b3`.
2. **Build → Authentication → Get started.**
   - Enable **Email/Password**.
   - Enable **Phone**. Under **Phone numbers for testing**, add a few test numbers with fixed codes. They're free and need no real SMS. For example:
     - `+91 99999 00001`, code `123456` (citizen)
     - `+91 99999 00002`, code `123456` (doctor)
     - `+91 99999 00003`, code `123456` (admin)
3. **Build → Firestore Database → Create database.** Pick location **asia-south1 (Mumbai)** and **production mode**.
4. **Project settings (⚙) → General → Your apps:**
   - Click **Web (</>)**, nickname `meditag-web`, and register. Copy the `firebaseConfig` it shows.
     - ✅ These values are public identifiers, so you can paste them to Claude.
   - Click **Android**, package name **`com.meditag.app`**, and register. Download `google-services.json` and save it to `app/android/app/google-services.json`. Git ignores this file.
5. **Project settings → Service accounts → Generate new private key.** This downloads a JSON file.
   - 🔒 This is the server's admin key. Don't share it. Step 5 puts it in your env file.

## 2. Firebase CLI (free, deploys the database security rules)

```bash
npm install -g firebase-tools
```
```bash
firebase login
```
```bash
cd D:\Meditag && firebase use --add
```
When asked, choose your project and type `default` as the alias.

## 3. Supabase (file storage)

1. Go to https://supabase.com → sign in with GitHub → **New project** → name it `meditag`, region **Mumbai (ap-south-1)**. Set a database password and save it somewhere safe; it isn't used here.
2. **Storage → New bucket** → name it `records`, and leave **Public bucket OFF** (private). Under the bucket's settings:
   - **Restrict file size:** 20 MB
   - **Allowed MIME types:** `application/pdf, image/jpeg, image/png, image/webp, image/heic`
3. **Project Settings → API:**
   - ✅ The **Project URL** is fine to share.
   - 🔒 The **service_role** key is secret.

## 4. Tag-signing keys

```bash
cd D:\Meditag\web
npm run keys
```
It prints three lines:
- 🔒 `TAG_SIGNING_KEY=…`
- 🔒 `TAG_SECRET_KEY=…`
- ✅ `NEXT_PUBLIC_TAG_PUBLIC_KEYS=…` (the public key, safe to share)

## 5. Create `web/.env.local`

Copy `web/.env.example` to `web/.env.local` and fill it in:

| Variable | Value |
|---|---|
| `NEXT_PUBLIC_FIREBASE_*` | From the web `firebaseConfig` (step 1.4) |
| 🔒 `FIREBASE_SERVICE_ACCOUNT` | The whole service-account JSON on one line, or that file base64-encoded (see below) |
| 🔒 `TAG_SIGNING_KEY`, `TAG_SECRET_KEY` | From step 4 |
| `NEXT_PUBLIC_TAG_PUBLIC_KEYS` | From step 4 |
| `SUPABASE_URL` | From step 3 |
| 🔒 `SUPABASE_SERVICE_ROLE_KEY` | From step 3 |

To base64-encode the service-account file in PowerShell:
```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("C:\path\to\serviceAccount.json"))
```

## 6. Vercel (do this after Claude confirms the code is ready)

1. Go to https://vercel.com → sign up with GitHub (Hobby, free) → **Add New → Project** → import **ADITYA-K-07/MediTag**.
2. Set **Root Directory** to `web`.
3. Under **Environment Variables**, add every variable from your `web/.env.local`. Also add `PUBLIC_BASE_URL`, set to the URL Vercel gives you, e.g. `https://meditag.vercel.app`.
4. Deploy. Every push to GitHub redeploys automatically.

## 7. Tell Claude

- ✅ Firebase **Project ID**
- ✅ Web **firebaseConfig**
- ✅ **Public key** line from step 4
- ✅ Supabase **Project URL**
- ✅ That `firebase login` worked and `web/.env.local` is filled in
