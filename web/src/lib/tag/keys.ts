import demoVectors from "../demo/test-vectors.json";
import type { PublicKeys } from "./envelope";

// Public keys the server signs tags with, as JSON {"<keyId>": "<uncompressed P-256 hex>"}.
// Set NEXT_PUBLIC_TAG_PUBLIC_KEYS from `npm --prefix functions run keys`.
// Without it the site runs in demo mode and trusts only the throwaway TEST key from schema/test-vectors.json.
const configured = process.env.NEXT_PUBLIC_TAG_PUBLIC_KEYS;

export const DEMO_MODE = !configured;

function parse(json: string): PublicKeys {
  try {
    return JSON.parse(json);
  } catch {
    return {};
  }
}

export const TAG_PUBLIC_KEYS: PublicKeys = configured ? parse(configured) : { 1: demoVectors.publicKeyHex };
