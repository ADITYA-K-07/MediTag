import { createCipheriv, createDecipheriv, randomBytes } from 'node:crypto';

// AES-256-GCM for small server-only secrets (tag passwords). Output: base64(iv[12] || authTag[16] || ciphertext).

export function sealSecret(plain: Uint8Array, key: Uint8Array): string {
  if (key.length !== 32) throw new Error('key must be 32 bytes');
  const iv = randomBytes(12);
  const cipher = createCipheriv('aes-256-gcm', key, iv);
  const ciphertext = Buffer.concat([cipher.update(plain), cipher.final()]);
  return Buffer.concat([iv, cipher.getAuthTag(), ciphertext]).toString('base64');
}

export function openSecret(sealed: string, key: Uint8Array): Buffer {
  const raw = Buffer.from(sealed, 'base64');
  const decipher = createDecipheriv('aes-256-gcm', key, raw.subarray(0, 12));
  decipher.setAuthTag(raw.subarray(12, 28));
  return Buffer.concat([decipher.update(raw.subarray(28)), decipher.final()]);
}
