import { createPublicKey, generateKeyPairSync, sign, verify } from 'node:crypto';

// ECDSA P-256 over SHA-256 with raw r||s signatures (IEEE P1363), the form WebCrypto and pointycastle expect.

export function signBytes(data: Uint8Array, privateKeyPem: string): Uint8Array {
  return sign('sha256', data, { key: privateKeyPem, dsaEncoding: 'ieee-p1363' });
}

export function verifyBytes(data: Uint8Array, signature: Uint8Array, publicKeyPem: string): boolean {
  try {
    return verify('sha256', data, { key: publicKeyPem, dsaEncoding: 'ieee-p1363' }, signature);
  } catch {
    return false;
  }
}

export function generateSigningKeyPair(): { privateKeyPem: string; publicKeyPem: string } {
  const { privateKey, publicKey } = generateKeyPairSync('ec', { namedCurve: 'P-256' });
  return {
    privateKeyPem: privateKey.export({ type: 'pkcs8', format: 'pem' }).toString(),
    publicKeyPem: publicKey.export({ type: 'spki', format: 'pem' }).toString(),
  };
}

/** Uncompressed public point (0x04 || X || Y, 65 bytes), for WebCrypto `importKey('raw')` and Dart clients. */
export function rawPublicKey(publicKeyPem: string): Uint8Array {
  const jwk = createPublicKey(publicKeyPem).export({ format: 'jwk' });
  const x = Buffer.from(jwk.x!, 'base64url');
  const y = Buffer.from(jwk.y!, 'base64url');
  return Buffer.concat([Buffer.from([0x04]), x, y]);
}
