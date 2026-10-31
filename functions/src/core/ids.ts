import { randomBytes } from 'node:crypto';

/** Random, unguessable tag id: 96 bits as 16 base64url characters. Never derived from personal data. */
export function newTagId(): string {
  return randomBytes(12).toString('base64url');
}

export const TAG_ID_PATTERN = /^[A-Za-z0-9_-]{16}$/;

/** NTAG216 write password (PWD, 4 bytes) and password acknowledge (PACK, 2 bytes). */
export interface TagPassword {
  pwd: Buffer;
  pack: Buffer;
}

export function newTagPassword(): TagPassword {
  return { pwd: randomBytes(4), pack: randomBytes(2) };
}
