// Decodes and verifies the application/vnd.meditag.v1 record. Format: schema/README.md.
// Must stay byte-compatible with functions/src/core/envelope.ts; schema/test-vectors.json checks both.
import type { TagPayload } from "./payload";

const HEADER_LENGTH = 3;
const SIGNATURE_LENGTH = 64;

export class EnvelopeError extends Error {}

export interface Envelope {
  json: Uint8Array<ArrayBuffer>;
  keyId: number;
  signature: Uint8Array<ArrayBuffer>;
}

export function decodeEnvelope(bytes: Uint8Array): Envelope {
  if (bytes.length < HEADER_LENGTH + 1 + SIGNATURE_LENGTH) throw new EnvelopeError("envelope too short");
  if (bytes[0] !== 1) throw new EnvelopeError(`unsupported envelope version ${bytes[0]}`);
  const jsonLength = (bytes[1] << 8) | bytes[2];
  if (bytes.length !== HEADER_LENGTH + jsonLength + 1 + SIGNATURE_LENGTH) throw new EnvelopeError("length mismatch");
  return {
    json: bytes.slice(HEADER_LENGTH, HEADER_LENGTH + jsonLength),
    keyId: bytes[HEADER_LENGTH + jsonLength],
    signature: bytes.slice(HEADER_LENGTH + jsonLength + 1),
  };
}

/** keyId → uncompressed P-256 public key (hex). */
export type PublicKeys = Record<number, string>;

export type ReadResult =
  | { status: "verified"; payload: TagPayload }
  | { status: "unverified"; payload: TagPayload | null }
  | { status: "unreadable"; error: string };

export function hexToBytes(hex: string): Uint8Array<ArrayBuffer> {
  const clean = hex.replace(/[^0-9a-f]/gi, "");
  const out = new Uint8Array(clean.length / 2);
  for (let i = 0; i < out.length; i++) out[i] = parseInt(clean.slice(i * 2, i * 2 + 2), 16);
  return out;
}

async function verifySignature(env: Envelope, publicKeyHex: string): Promise<boolean> {
  try {
    const key = await crypto.subtle.importKey("raw", hexToBytes(publicKeyHex), { name: "ECDSA", namedCurve: "P-256" }, false, ["verify"]);
    return await crypto.subtle.verify({ name: "ECDSA", hash: "SHA-256" }, key, env.signature, env.json);
  } catch {
    return false;
  }
}

function parsePayload(json: Uint8Array): TagPayload | null {
  try {
    const value = JSON.parse(new TextDecoder().decode(json));
    return value && value.v === 1 && typeof value.n === "string" ? (value as TagPayload) : null;
  } catch {
    return null;
  }
}

/**
 * Works fully offline. An unverified payload is still returned so a bystander can see it,
 * but the UI must show it with the "Unverified" warning.
 */
export async function readEnvelope(bytes: Uint8Array, keys: PublicKeys): Promise<ReadResult> {
  let env: Envelope;
  try {
    env = decodeEnvelope(bytes);
  } catch (e) {
    return { status: "unreadable", error: (e as Error).message };
  }
  const payload = parsePayload(env.json);
  const key = keys[env.keyId];
  if (payload && key && (await verifySignature(env, key))) return { status: "verified", payload };
  return { status: "unverified", payload };
}
