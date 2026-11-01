import { describe, expect, it } from 'vitest';
import { decideAccess, normaliseUid, TAP_WINDOW_MS } from './access';
import { decodeEnvelope, encodeEnvelope, EnvelopeError } from './envelope';
import { newTagId, newTagPassword, TAG_ID_PATTERN } from './ids';
import { fitsOnNtag216, NTAG216_USER_BYTES, tagBytesNeeded, uriPayloadLength } from './ndef';
import { buildPayload, EmergencyProfile, validatePayload } from './payload';
import { openSecret, sealSecret } from './secrets';
import { generateSigningKeyPair, rawPublicKey, signBytes, verifyBytes } from './signing';
import { planTagWrite, TagWriteError } from './tagWrite';

const keys = generateSigningKeyPair();
const NOW = Date.UTC(2026, 9, 31, 12, 0, 0);

const rahul: EmergencyProfile = {
  name: 'Rahul Sharma',
  dob: '1998-04-12',
  sex: 'M',
  bloodGroup: 'B+',
  allergies: ['Penicillin', 'Peanuts'],
  conditions: ['Type 1 Diabetes', 'HIV'],
  medications: ['Insulin glargine 20u'],
  organDonor: true,
  emergencyContacts: [
    { name: 'Priya Sharma', relation: 'Mother', phone: '+919876543210' },
    { name: 'Arjun Sharma', relation: 'Brother', phone: '+919123456780' },
  ],
  onTagFields: { dob: true, bloodGroup: true, allergies: true, medications: true, organDonor: true, emergencyContacts: true },
};

describe('ids', () => {
  it('makes 16-char base64url tag ids', () => {
    const ids = new Set(Array.from({ length: 200 }, newTagId));
    expect(ids.size).toBe(200);
    for (const id of ids) expect(id).toMatch(TAG_ID_PATTERN);
  });

  it('makes a 4-byte password and 2-byte pack', () => {
    const { pwd, pack } = newTagPassword();
    expect(pwd).toHaveLength(4);
    expect(pack).toHaveLength(2);
  });
});

describe('payload', () => {
  it('keeps only fields marked on-tag', () => {
    const p = buildPayload(rahul, 'k8Fq2xLm9Pz4Rt7W', 1761900000);
    expect(p.bg).toBe('B+');
    expect(p.al).toEqual(['Penicillin', 'Peanuts']);
    expect(p.cc).toBeUndefined(); // conditions stay cloud-only here
    expect(p.sx).toBeUndefined();
    expect(p.ec?.[0]).toEqual({ n: 'Priya Sharma', r: 'Mother', p: '+919876543210' });
    expect(Object.values(p)).not.toContain(undefined);
    expect(validatePayload(p)).toEqual([]);
  });

  it('always includes the name and nothing else when no fields are on-tag', () => {
    const p = buildPayload({ ...rahul, onTagFields: {} }, 'k8Fq2xLm9Pz4Rt7W', 1);
    expect(Object.keys(p).sort()).toEqual(['n', 'tid', 'ts', 'v']);
  });

  it('reports invalid phone numbers and oversize lists', () => {
    const p = buildPayload(
      {
        ...rahul,
        allergies: Array.from({ length: 9 }, (_, i) => `A${i}`),
        emergencyContacts: [{ name: 'X', phone: '98765' }],
      },
      'k8Fq2xLm9Pz4Rt7W',
      1,
    );
    const errors = validatePayload(p);
    expect(errors).toContain('al: at most 8 items');
    expect(errors.some((e) => e.startsWith('ec[0].p'))).toBe(true);
  });
});

describe('envelope + signature', () => {
  const json = new TextEncoder().encode('{"v":1,"n":"Test"}');

  it('round-trips and verifies', () => {
    const env = encodeEnvelope({ json, keyId: 1, signature: signBytes(json, keys.privateKeyPem) });
    const back = decodeEnvelope(env);
    expect(new TextDecoder().decode(back.json)).toBe('{"v":1,"n":"Test"}');
    expect(back.keyId).toBe(1);
    expect(verifyBytes(back.json, back.signature, keys.publicKeyPem)).toBe(true);
  });

  it('rejects a payload edited after signing', () => {
    const env = encodeEnvelope({ json, keyId: 1, signature: signBytes(json, keys.privateKeyPem) });
    env[10] ^= 0x01; // flip one bit inside the JSON
    const back = decodeEnvelope(env);
    expect(verifyBytes(back.json, back.signature, keys.publicKeyPem)).toBe(false);
  });

  it('rejects a signature from a different key', () => {
    const other = generateSigningKeyPair();
    const sig = signBytes(json, other.privateKeyPem);
    expect(verifyBytes(json, sig, keys.publicKeyPem)).toBe(false);
  });

  it('rejects malformed envelopes', () => {
    expect(() => decodeEnvelope(new Uint8Array(10))).toThrow(EnvelopeError);
    const env = encodeEnvelope({ json, keyId: 1, signature: new Uint8Array(64) });
    expect(() => decodeEnvelope(env.slice(0, env.length - 1))).toThrow('length mismatch');
    env[0] = 9;
    expect(() => decodeEnvelope(env)).toThrow('unsupported envelope version');
  });

  it('exports a 65-byte uncompressed public key', () => {
    const raw = rawPublicKey(keys.publicKeyPem);
    expect(raw).toHaveLength(65);
    expect(raw[0]).toBe(0x04);
  });
});

describe('ndef budget', () => {
  it('compresses the https:// prefix to one byte', () => {
    expect(uriPayloadLength('https://meditag.app/e/k8Fq2xLm9Pz4Rt7W')).toBe(1 + 'meditag.app/e/k8Fq2xLm9Pz4Rt7W'.length);
  });

  it('flags messages larger than 888 bytes', () => {
    const uri = 'https://meditag.app/e/k8Fq2xLm9Pz4Rt7W';
    expect(fitsOnNtag216({ uri, envelopeLength: 500 })).toBe(true);
    expect(fitsOnNtag216({ uri, envelopeLength: 800 })).toBe(false);
    expect(tagBytesNeeded({ uri, envelopeLength: 500 })).toBeLessThan(NTAG216_USER_BYTES);
  });
});

describe('planTagWrite', () => {
  const opts = { tagId: 'k8Fq2xLm9Pz4Rt7W', baseUrl: 'https://meditag.app/', signingKey: keys.privateKeyPem, keyId: 1, now: NOW };

  it('produces a signed envelope that fits the tag and verifies', () => {
    const plan = planTagWrite({ ...opts, profile: rahul });
    expect(plan.uri).toBe('https://meditag.app/e/k8Fq2xLm9Pz4Rt7W');
    expect(plan.bytesNeeded).toBeLessThanOrEqual(888);
    const env = decodeEnvelope(Buffer.from(plan.envelope, 'base64'));
    expect(verifyBytes(env.json, env.signature, keys.publicKeyPem)).toBe(true);
    expect(JSON.parse(new TextDecoder().decode(env.json))).toMatchObject({ tid: opts.tagId, bg: 'B+', ts: NOW / 1000 });
  });

  it('refuses profiles that are too big for the tag', () => {
    const long = (n: number) => Array.from({ length: n }, (_, i) => `${'x'.repeat(36)}${i}`);
    const huge: EmergencyProfile = {
      ...rahul,
      allergies: long(8),
      conditions: long(6),
      medications: long(6),
      onTagFields: { ...rahul.onTagFields, conditions: true },
    };
    expect(() => planTagWrite({ ...opts, profile: huge })).toThrow(TagWriteError);
  });

  it('refuses invalid profiles with details', () => {
    try {
      planTagWrite({ ...opts, profile: { ...rahul, name: '' } });
      expect.unreachable();
    } catch (e) {
      expect(e).toBeInstanceOf(TagWriteError);
      expect((e as TagWriteError).details[0]).toMatch(/^n:/);
    }
  });
});

describe('secrets', () => {
  it('seals and opens tag passwords', () => {
    const key = new Uint8Array(32).fill(7);
    const sealed = sealSecret(Buffer.from([1, 2, 3, 4]), key);
    expect([...openSecret(sealed, key)]).toEqual([1, 2, 3, 4]);
    expect(() => openSecret(sealed, new Uint8Array(32).fill(8))).toThrow();
  });
});

describe('decideAccess', () => {
  const tag = { status: 'active' as const, nfcUid: '04:A2:1B:C3:D4:E5:F6' };
  const base = { doctorVerified: true, tag, nfcUid: '04a21bc3d4e5f6', tappedAt: NOW - 4000, now: NOW };

  it('grants 24 h access after a fresh tap', () => {
    expect(decideAccess(base)).toEqual({ ok: true, expiresAt: NOW + 24 * 3600 * 1000 });
  });

  it.each([
    [{ doctorVerified: false }, 'doctor-not-verified'],
    [{ tag: null }, 'tag-not-found'],
    [{ tag: { ...tag, status: 'revoked' as const } }, 'tag-inactive'],
    [{ nfcUid: '04FFFFFFFFFFFF' }, 'tag-mismatch'],
    [{ tappedAt: NOW - TAP_WINDOW_MS - 1 }, 'tap-expired'],
    [{ tappedAt: NOW + 10 * 60 * 1000 }, 'tap-expired'],
  ])('denies %o as %s', (override, reason) => {
    expect(decideAccess({ ...base, ...override })).toEqual({ ok: false, reason });
  });

  it('normalises UIDs from different platforms', () => {
    expect(normaliseUid('04:a2:1b')).toBe(normaliseUid('04A21B'));
  });
});
