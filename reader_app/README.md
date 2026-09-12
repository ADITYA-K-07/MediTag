# MediTag Reader

Flutter source for reading one NDEF record from an NTAG213 and verifying its P-256 signature locally. The reader intentionally works with no API connection after provisioning.

## Before running

1. Start the backend and copy `public_key_base64` from `GET /public-key` into `_provisionedPublicKey` in `lib/main.dart`.
2. Run `flutter pub get` then `flutter run` on a physical NFC-capable phone.
3. For an iPhone build, enable **Near Field Communication Tag Reading** for the app ID in your Apple Developer account; the project already includes the entitlement and usage description.

The writer app is deliberately not included yet; use the API's issue response to create the single binary NDEF record for the initial hardware test.
