// Rules for giving a doctor 24-hour access to a patient's full record.

export const TAP_WINDOW_MS = 10 * 60 * 1000;
export const CLOCK_SKEW_MS = 2 * 60 * 1000;
export const ACCESS_DURATION_MS = 24 * 60 * 60 * 1000;
export const MAX_ACTIVE_TAGS = 3;

export type TagStatus = 'pending' | 'active' | 'revoked';

export type AccessDenial = 'doctor-not-verified' | 'tag-not-found' | 'tag-inactive' | 'tag-mismatch' | 'tap-expired';

export interface AccessRequest {
  doctorVerified: boolean;
  tag: { status: TagStatus; nfcUid?: string } | null;
  /** Chip UID the doctor's phone read during the tap. */
  nfcUid: string;
  /** When the doctor's phone read the tag (ms since epoch). */
  tappedAt: number;
  now: number;
}

export type AccessDecision = { ok: true; expiresAt: number } | { ok: false; reason: AccessDenial };

/**
 * Proof of presence: the doctor must be verified and must have read this exact chip within the last
 * 10 minutes. The tap time comes from the client, so this deters casual lookups rather than proving
 * presence. Audit logs and patient notifications cover the rest.
 */
export function decideAccess({ doctorVerified, tag, nfcUid, tappedAt, now }: AccessRequest): AccessDecision {
  if (!doctorVerified) return { ok: false, reason: 'doctor-not-verified' };
  if (!tag) return { ok: false, reason: 'tag-not-found' };
  if (tag.status !== 'active') return { ok: false, reason: 'tag-inactive' };
  if (!tag.nfcUid || normaliseUid(tag.nfcUid) !== normaliseUid(nfcUid)) return { ok: false, reason: 'tag-mismatch' };
  if (tappedAt > now + CLOCK_SKEW_MS || now - tappedAt > TAP_WINDOW_MS) return { ok: false, reason: 'tap-expired' };
  return { ok: true, expiresAt: now + ACCESS_DURATION_MS };
}

/** NFC UIDs arrive as "04:A2:1B…", "04a21b…" etc. depending on platform. */
export function normaliseUid(uid: string): string {
  return uid.replace(/[^0-9a-f]/gi, '').toUpperCase();
}
