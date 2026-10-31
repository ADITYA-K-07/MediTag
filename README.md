# MediTag

An NFC tag that carries a person's emergency medical info offline, plus a secure link to their full history in the cloud. Anyone can scan a tag to see blood group and allergies and call the person's family. Verified doctors can open the full medical history. See [PLAN.md](PLAN.md) for the full design and [design/mockups](design/mockups) for the UI mockups.

## Repository

| Folder | What |
|---|---|
| `functions/` | Firebase Cloud Functions (TypeScript): tag payload signing, tag passwords, doctor access grants, admin review |
| `web/` | Website (Next.js PWA): home page, **Scan a MediTag** (Web NFC), public emergency page `/e/<tagId>` |
| `app/` | Mobile app (Flutter): **Scan a MediTag** with offline signature check |
| `schema/` | Shared tag format: payload JSON Schema, binary envelope spec, cross-platform test vectors |
| `design/` | Design tokens (`tokens.json` → CSS + Dart) and mockups |
| `firestore.rules`, `storage.rules` | Who can read and write what |

## How a tag is trusted

The server signs each tag's emergency data with ECDSA P-256. The website and app check that signature **offline** with the public key, so a tag someone edited shows as **Unverified**. The same `schema/test-vectors.json` is checked by the server, website and app test suites, so all three agree byte for byte.

## Running it

```bash
# Server logic tests
npm --prefix functions install
npm --prefix functions test

# Website (demo mode works without Firebase: try the demo tags on /scan)
npm --prefix web install
npm --prefix web run dev       # http://localhost:3000
npm --prefix web test

# Mobile app
cd app && flutter test && flutter run
```

Without configured keys, the website and app run in **demo mode**: they trust only the throwaway test key in `schema/test-vectors.json` and offer "Genuine tag" and "Tampered tag" buttons, so you can demo without hardware.

### Real keys

```bash
npm --prefix functions run keys          # prints the private key, public key and password-encryption key
npx firebase-tools functions:secrets:set TAG_SIGNING_KEY
npx firebase-tools functions:secrets:set TAG_SECRET_KEY
```

Give the clients the public key:

- **Website:** `NEXT_PUBLIC_TAG_PUBLIC_KEYS='{"1":"04…"}'`
- **App:** `flutter run --dart-define=TAG_PUBLIC_KEYS='{"1":"04…"}'`

After changing the tag format, run `npm --prefix functions run vectors` to regenerate the shared test vectors.

### Design tokens

Edit `design/tokens.json`, then run `node design/build-tokens.mjs` to regenerate `web/src/styles/tokens.css` and `app/lib/theme/tokens.dart`.
