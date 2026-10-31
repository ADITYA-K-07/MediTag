# Shared schemas

Contracts shared by the Cloud Functions, the website and the Flutter app.

## Tag payload envelope (`application/vnd.meditag.v1`)

The MIME record's payload is a binary envelope, so clients verify the exact bytes the server signed and never re-serialise JSON:

| Bytes | Field |
|---|---|
| 1 | Envelope version (`0x01`) |
| 2 | JSON length *L*, big-endian |
| *L* | UTF-8 JSON matching `tag-payload.schema.json` |
| 1 | Key id (which server key signed it, for key rotation) |
| 64 | ECDSA P-256 / SHA-256 signature over the JSON bytes, raw `r‖s` (IEEE P1363) |

The format uses raw `r‖s` because WebCrypto produces and checks signatures in that form. Node's `crypto` uses it with `dsaEncoding: 'ieee-p1363'`.

## NDEF message on the tag

1. URI record: `https://meditag.app/e/<tid>`. It comes first, so phones without the app open the website.
2. MIME record: `application/vnd.meditag.v1` holding the envelope above.
3. Android Application Record: `com.meditag.app`.

The whole message, plus its TLV wrapper, must fit in the NTAG216's 888 bytes of user memory. `functions/src/core/ndef.ts` computes this budget.
