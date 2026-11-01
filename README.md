# MediTag

An NFC tag that carries a person's emergency medical info offline, plus a secure link to their full history in the cloud. Anyone can scan a tag to see blood group and allergies and call the person's family. Verified doctors can open the full medical history. See [PLAN.md](PLAN.md) for the design, [design/mockups](design/mockups) for the UI mockups, and **[SETUP.md](SETUP.md) to create the free accounts**.

## Free-tier architecture

| Piece | Runs on | Cost |
|---|---|---|
| Login and database | Firebase **Spark**: Auth + Firestore | Free |
| Website **and server logic** (tag signing, doctor access, admin review, file links) | Next.js on Vercel **Hobby**: pages + `/api/*` routes using the Firebase Admin SDK | Free |
| Medical files (PDFs, scans) | Supabase Storage, private bucket | Free (1 GB) |
| Mobile app | Flutter (Android / iOS) | Free |

## Repository

| Folder | What |
|---|---|
| `web/` | Website + API. `src/app` holds the pages and `/api` routes; `src/server` holds server-only logic; `src/server/core` holds the pure, unit-tested tag and access rules. |
| `app/` | Mobile app (Flutter): **Scan a MediTag** with offline signature check |
| `schema/` | Shared tag format: payload JSON Schema, binary envelope spec, cross-platform test vectors |
| `design/` | Design tokens (`tokens.json` → CSS + Dart) and mockups |
| `firestore.rules` | Who can read and write what in Firestore (deploy with `firebase deploy --only firestore`) |

### API (all need `Authorization: Bearer <Firebase ID token>`)

| Route | Who | Does |
|---|---|---|
| `POST /api/tags` `{label}` | Citizen | Signed payload + write password for a new tag (max 3 active) |
| `POST /api/tags/:id/confirm` `{nfcUid}` | Citizen | Activates the tag after the app read it back |
| `POST /api/tags/:id/rewrite` | Citizen | Re-signs the profile and returns the tag password to update it |
| `POST /api/tags/:id/revoke` | Citizen | Deactivates a lost tag |
| `POST /api/access` `{tagId, nfcUid, tappedAt}` | Verified doctor | 24-hour access after a tap; logged and the patient is notified |
| `POST /api/admin/doctors/:uid/review` `{approve, reason?}` | Admin | Approves or rejects a doctor |
| `POST /api/files/upload` `{fileName, contentType, size}` | Citizen | Signed upload URL into their private folder |
| `POST /api/files/download` `{path}` | Owner / granted doctor | 5-minute download link |

The public emergency page `/e/<tagId>` reads Firestore directly on the server.

## How a tag is trusted

The server signs each tag's emergency data with ECDSA P-256. The website and app check that signature **offline** with the public key, so a tag someone edited shows as **Unverified**. The same `schema/test-vectors.json` is checked by the server, website and app test suites, so all three agree byte for byte.

## Running it

```bash
cd web
npm install
npm test            # tag format, signing, access rules
npm run dev         # http://localhost:3000
```

```bash
cd app
flutter test
flutter run --dart-define=TAG_PUBLIC_KEYS='{"1":"04…"}'
```

Without `web/.env.local` (see `web/.env.example`), the site runs in **demo mode**:
- `/scan` offers "Genuine tag" and "Tampered tag" buttons using the throwaway test key.
- `/e/k8Fq2xLm9Pz4Rt7W` shows the demo person.
- The API answers `503 not configured`.

The app has the same demo mode when built without `TAG_PUBLIC_KEYS`.

After changing the tag format, run `npm run vectors` in `web/` to regenerate the shared test vectors.

### Design tokens

Edit `design/tokens.json`, then run `node design/build-tokens.mjs` to regenerate `web/src/styles/tokens.css` and `app/lib/theme/tokens.dart`.
