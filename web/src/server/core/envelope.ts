// Binary envelope for the application/vnd.meditag.v1 record:
//   [version:1][jsonLength:2 BE][json:L][keyId:1][signature:64]
// See schema/README.md. Uses Uint8Array only so the same logic ports directly to the web and Dart clients.

export const ENVELOPE_VERSION = 1;
export const SIGNATURE_LENGTH = 64;
const HEADER_LENGTH = 3;
const MAX_JSON_LENGTH = 0xffff;

export interface Envelope {
  json: Uint8Array;
  keyId: number;
  signature: Uint8Array;
}

export class EnvelopeError extends Error {}

export function encodeEnvelope({ json, keyId, signature }: Envelope): Uint8Array {
  if (json.length > MAX_JSON_LENGTH) throw new EnvelopeError('payload too large');
  if (signature.length !== SIGNATURE_LENGTH) throw new EnvelopeError('signature must be 64 bytes');
  if (!Number.isInteger(keyId) || keyId < 0 || keyId > 255) throw new EnvelopeError('keyId must fit in one byte');
  const out = new Uint8Array(HEADER_LENGTH + json.length + 1 + SIGNATURE_LENGTH);
  out[0] = ENVELOPE_VERSION;
  out[1] = json.length >> 8;
  out[2] = json.length & 0xff;
  out.set(json, HEADER_LENGTH);
  out[HEADER_LENGTH + json.length] = keyId;
  out.set(signature, HEADER_LENGTH + json.length + 1);
  return out;
}

export function decodeEnvelope(bytes: Uint8Array): Envelope {
  if (bytes.length < HEADER_LENGTH + 1 + SIGNATURE_LENGTH) throw new EnvelopeError('envelope too short');
  if (bytes[0] !== ENVELOPE_VERSION) throw new EnvelopeError(`unsupported envelope version ${bytes[0]}`);
  const jsonLength = (bytes[1] << 8) | bytes[2];
  if (bytes.length !== HEADER_LENGTH + jsonLength + 1 + SIGNATURE_LENGTH) throw new EnvelopeError('length mismatch');
  return {
    json: bytes.slice(HEADER_LENGTH, HEADER_LENGTH + jsonLength),
    keyId: bytes[HEADER_LENGTH + jsonLength],
    signature: bytes.slice(HEADER_LENGTH + jsonLength + 1),
  };
}
