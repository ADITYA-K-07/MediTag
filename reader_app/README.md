# MediTag Reader

Flutter source for reading one NDEF record from an NTAG213 and verifying its P-256 signature locally. The reader intentionally works with no API connection after provisioning.

## Before running

1. Start the backend and obtain `public_key_base64` from `GET /public-key`.
2. Run with build-time configuration (credentials are never committed):
   ```powershell
   flutter run --dart-define=MEDITAG_PUBLIC_KEY=<public_key_base64> --dart-define=MEDITAG_API_BASE_URL=http://<server>:8000 --dart-define=MEDITAG_CLINICIAN_TOKEN=<clinician_token>
   ```
   The API URL and token are used only for Tier 2. Tier 1 verification uses the provisioned public key locally and remains offline.
3. Use a physical NFC-capable phone. For iPhone, enable **Near Field Communication Tag Reading** for the app ID; the project already includes the entitlement and usage description.

The Issue Tag screen deliberately stops at its destructive-write confirmation; NFC writing is not included yet. Use the API's issue response to create the single binary NDEF record for the initial hardware test.

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
