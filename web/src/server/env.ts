import "server-only";

// Server-only configuration. Values come from web/.env.local locally and from Vercel's Environment Variables
// in production (see SETUP.md). Multi-line secrets may be given raw or base64-encoded.

function decodeMaybeBase64(value: string, looksDecoded: (s: string) => boolean): string {
  if (looksDecoded(value)) return value;
  return Buffer.from(value, "base64").toString("utf8");
}

function required(name: string): string {
  const value = process.env[name];
  if (!value) throw new Error(`${name} is not set. See SETUP.md.`);
  return value;
}

/** True when the Firebase Admin credentials are configured; otherwise the site runs in demo mode. */
export const serverConfigured = Boolean(process.env.FIREBASE_SERVICE_ACCOUNT);

export const env = {
  serviceAccount: () => JSON.parse(decodeMaybeBase64(required("FIREBASE_SERVICE_ACCOUNT"), (s) => s.trimStart().startsWith("{"))),
  signingKeyPem: () => decodeMaybeBase64(required("TAG_SIGNING_KEY"), (s) => s.includes("BEGIN")),
  signingKeyId: () => Number(process.env.TAG_SIGNING_KEY_ID ?? "1"),
  /** 32-byte key that encrypts NTAG passwords at rest. */
  secretKey: () => Buffer.from(required("TAG_SECRET_KEY"), "base64"),
  publicBaseUrl: () => process.env.PUBLIC_BASE_URL ?? "https://meditag.vercel.app",
  supabaseUrl: () => required("SUPABASE_URL"),
  supabaseServiceKey: () => required("SUPABASE_SERVICE_ROLE_KEY"),
  supabaseBucket: () => process.env.SUPABASE_BUCKET ?? "records",
};
