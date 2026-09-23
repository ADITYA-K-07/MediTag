# MediTag API

The API issues a signed, 79-byte Tier 1 NFC payload and stores the associated Tier 2 demo record in SQLite. It is an MVP: set real secrets before sharing the API, and do not put real patient data in the demo database.

For a short-lived review deployment, Render can run this service from the
`backend/` directory. The repository includes [`../render.yaml`](../render.yaml)
and a step-by-step [`../DEPLOY_DEMO.md`](../DEPLOY_DEMO.md). Set
`MEDITAG_PRIVATE_KEY_BASE64` in the host so the issuer key remains stable if the
service restarts.

## Run locally

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -r requirements.txt
$env:MEDITAG_ADMIN_TOKEN = "choose-a-long-admin-secret"
$env:MEDITAG_CLINICIAN_TOKEN = "choose-a-long-clinician-secret"
uvicorn app.main:app --reload
```

Open `http://127.0.0.1:8000/docs` for the interactive API. First obtain `GET /public-key`; copy its `public_key_base64` into `reader_app/lib/main.dart` before building the reader. The public key is deliberately embedded in the app so Tier 1 verification never makes a network request.

## Issue a demo tag

Send `POST /tags/issue` with `X-Admin-Token`. A valid body is:

```json
{
  "tag_id": 1001,
  "blood_type": 8,
  "allergies": ["penicillin", "latex"],
  "critical_conditions": ["diabetes"],
  "emergency_phone": "+91 9876543210",
  "tier2_record": {"medications": ["Demo only"]}
}
```

Write the returned `ndef_payload_base64` as the payload of exactly one NDEF record with TNF `unknown`, an empty type, and an empty identifier. The resulting NDEF message is 82 bytes; with Type 2 TLV framing it uses 86 of the NTAG213's 144 usable bytes.

`GET /tags/{tag_id}/tier2` requires `Authorization: Bearer <MEDITAG_CLINICIAN_TOKEN>`. This is role-gating for the demo, not a production identity-verification system.
