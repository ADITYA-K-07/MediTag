# MediTag

An NFC-based medical ID tag system built as a semester project. Tap a tag with any phone and get instant, offline-verifiable emergency medical info — with a fuller record available online to authorized personnel.

## The idea

Most medical ID tags are either dumb (a static engraving) or need connectivity to be useful. MediTag splits the data into two tiers:

- **Tier 1 — on-tag, offline.** Critical info (blood type, allergies, key conditions, one emergency contact) stored directly on the NFC tag itself. Readable instantly by anyone, with zero network connection, and cryptographically signed so a reader can verify it hasn't been tampered with — even offline.
- **Tier 2 — cloud, gated.** The full medical record (complete history, medications, multiple contacts, physician details) fetched from a backend, shown only to authenticated, authorized roles when the device is online.

The core technical challenge: proving Tier 1 data is authentic with no network connection, on a chip with only 144 bytes of usable memory.

## Hardware

DIGINESS NTAG213 NFC stickers — NFC Forum Type 2 Tag, 13.56 MHz, 144 bytes usable memory. Same NTAG21x family as NTAG215/216, so the chip also ships with a factory-programmed ECDSA originality signature (a possible future anti-cloning check).

## Architecture

```
Python backend  --signs & writes-->  NFC tag  --tap-->  Reader app (verifies offline)
      ^                                                         |
      |__________________ tier2 fetch (online + authorized) ____|
```

- **Reader/writer app:** Flutter (cross-platform, `nfc_manager`) — chosen over a website because Web NFC has no support in Safari/iOS or any desktop browser, can't access the low-level chip commands needed for anti-cloning checks, and would require connectivity just to load, defeating the point of an offline-verifiable tag.
- **Backend:** Python (FastAPI), with a `cryptography`-based ECDSA sign/verify flow.
- **Signing scheme:** ECDSA (P-256), asymmetric — the private key stays server-side, the public key ships inside the app for offline verification. Chosen over HMAC specifically because a symmetric key would have to live inside the app binary, making it extractable and forgeable.

## Status

Early build phase — see [`EDI.md`](./EDI.md) for the full living project spec, current build priorities, open design questions, and a session-by-session log of what's been done and what's next.

## Not in scope yet

- ABDM/ABHA (India's national health ID) integration
- SMS fallback tier for low/no-connectivity areas
- Auto-trigger on impact (accelerometer-based emergency alert)
- 108/112 emergency services API integration

These are deliberately deferred until the core tap → verify → reveal loop is solid.

## Patent note

This project is being evaluated for patentability in India as part of the coursework. See `EDI.md` for the current thinking on novelty and disclosure timing — nothing here should be treated as a filed or pending patent claim.

## Documentation

All project decisions, architecture details, the exact on-tag byte layout, and progress logs live in [`EDI.md`](./EDI.md) — that file is the source of truth and is updated after every work session.
