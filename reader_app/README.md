# MediTag Reader

Flutter source for reading one NDEF record from an NTAG213 and verifying its P-256 signature locally. The reader intentionally works with no API connection after provisioning.

## Before running

1. Start the backend and obtain `public_key_base64` from `GET /public-key`.
2. Run with build-time configuration (credentials are never committed):
   ```powershell
   flutter run --dart-define=MEDITAG_PUBLIC_KEY=<public_key_base64> --dart-define=MEDITAG_API_BASE_URL=http://<server>:8000 --dart-define=MEDITAG_ADMIN_TOKEN=<admin_token> --dart-define=MEDITAG_CLINICIAN_TOKEN=<clinician_token>
   ```
   The admin token is used only by the temporary demo writer; do not ship it in a production build. The clinician token is used only for Tier 2. Tier 1 verification uses the provisioned public key locally and remains offline.
3. Use a physical NFC-capable phone. For iPhone, enable **Near Field Communication Tag Reading** for the app ID; the project already includes the entitlement and usage description.

The Issue Tag screen can now request a signed emergency payload and write it to a writable NTAG213. It deliberately does not lock the tag. For an Android demo with a local FastAPI server, bind Uvicorn to the LAN and use the computer's local IP in `MEDITAG_API_BASE_URL`:

```powershell
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

Keep the phone and computer on the same network. After writing, return to
`Read a MediTag`, scan the tag, and show `Verified offline`.

## Source layout

```text
lib/
|- main.dart                 App bootstrap and top-level surface routing
|- features/
|  |- access/                Three-surface entry portal
|  |- citizen/               Citizen sign-in and profile-management UI
|  |- doctor/                Clinician sign-in and scan workspace
|  `- reader/                Anonymous NFC reader and Tier 1/Tier 2 screens
|- services/                 NFC scan and Tier 2 API adapters
|- theme/                    Design tokens and application theme
|- widgets/                  Shared MediTag UI components
|- protocol.dart             Compact Tier 1 decoder
|- tag_verifier.dart         Offline P-256 verification
`- reader_controller.dart    Reader state and flow coordination
```

Keep protocol logic, I/O services, state coordination, and presentation in
their existing layers. New screens should live under the appropriate feature
folder rather than expanding `main.dart`.

## Quality checks

```powershell
flutter analyze
flutter test
```
