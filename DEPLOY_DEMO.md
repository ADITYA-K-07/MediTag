# Review demo deployment

This is the shortest path to a shareable Android demo: deploy the FastAPI
backend to Render, build one APK with the hosted URL, and share the APK file.

## Deploy the backend

1. Open Render and create a Web Service from the `ADITYA-K-07/MediTag` GitHub
   repository.
2. Use the repository's `render.yaml`, or configure these values manually:
   - Root directory: `backend`
   - Build command: `pip install -r requirements.txt`
   - Start command: `uvicorn app.main:app --host 0.0.0.0 --port $PORT`
   - Health check: `/health`
3. Add secrets in Render:
   - `MEDITAG_ADMIN_TOKEN` — a temporary review-only token
   - `MEDITAG_CLINICIAN_TOKEN` — a temporary review-only token
   - `MEDITAG_PRIVATE_KEY_BASE64` — a base64-encoded P-256 private PEM key

If the local backend has already generated `backend/data/issuer-p256-private.pem`,
encode that same file in PowerShell and paste the output into Render:

```powershell
[Convert]::ToBase64String(
  [IO.File]::ReadAllBytes("backend/data/issuer-p256-private.pem")
)
```

If that file does not exist yet, start the backend once locally first so it can
generate the issuer key.
4. Wait for the service to deploy and confirm `https://<service>.onrender.com/health`
   returns `{"status":"ok"}`.

The private key must remain secret. Supplying it through an environment
variable keeps the issuer public key stable across service restarts. Do not
embed the private key in the Android build.

## Build the Android APK

From `reader_app/`, fetch the public key from the deployed service, then build:

```powershell
$api = "https://<service>.onrender.com"
$publicKey = (Invoke-RestMethod "$api/public-key").public_key_base64

flutter pub get
flutter build apk --debug `
  "--dart-define=MEDITAG_PUBLIC_KEY=$publicKey" `
  "--dart-define=MEDITAG_API_BASE_URL=$api" `
  "--dart-define=MEDITAG_ADMIN_TOKEN=<review-admin-token>"
```

Share `build\app\outputs\flutter-apk\app-debug.apk` with the Android phone.
The app can then issue and write the emergency Tier 1 payload through the
hosted API, and read/verify it offline.

The admin token is intentionally included only for this review build. It must
be removed when the writer is replaced by a protected administrator workflow.
