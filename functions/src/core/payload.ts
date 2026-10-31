// Tier-1 emergency payload stored on the tag. See schema/tag-payload.schema.json and schema/README.md.
import { TAG_ID_PATTERN } from './ids';

export const PAYLOAD_VERSION = 1;
export const BLOOD_GROUPS = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'] as const;
export type BloodGroup = (typeof BLOOD_GROUPS)[number];

export interface TagContact {
  n: string;
  r?: string;
  p: string;
}

export interface TagPayload {
  v: typeof PAYLOAD_VERSION;
  tid: string;
  n: string;
  dob?: string;
  sx?: 'M' | 'F' | 'O';
  bg?: BloodGroup;
  al?: string[];
  cc?: string[];
  med?: string[];
  org?: boolean;
  ec?: TagContact[];
  ts: number;
}

/** The citizen's emergency profile as stored in Firestore (emergencyProfiles/{uid}). */
export interface EmergencyProfile {
  name: string;
  dob?: string;
  sex?: 'M' | 'F' | 'O';
  bloodGroup?: BloodGroup;
  allergies?: string[];
  conditions?: string[];
  medications?: string[];
  organDonor?: boolean;
  emergencyContacts?: { name: string; relation?: string; phone: string }[];
  /** Which fields the citizen chose to put on the tag. Missing or false = cloud only. Name is always on the tag. */
  onTagFields?: Partial<Record<OnTagField, boolean>>;
}

export type OnTagField =
  | 'dob'
  | 'sex'
  | 'bloodGroup'
  | 'allergies'
  | 'conditions'
  | 'medications'
  | 'organDonor'
  | 'emergencyContacts';

const nonEmpty = <T>(list: T[] | undefined): T[] | undefined => (list && list.length > 0 ? list : undefined);

/** Builds the on-tag payload from a profile, keeping only the fields the citizen marked "on tag". */
export function buildPayload(profile: EmergencyProfile, tid: string, ts: number): TagPayload {
  const on = profile.onTagFields ?? {};
  const payload: TagPayload = { v: PAYLOAD_VERSION, tid, n: profile.name.trim(), ts };
  if (on.dob && profile.dob) payload.dob = profile.dob;
  if (on.sex && profile.sex) payload.sx = profile.sex;
  if (on.bloodGroup && profile.bloodGroup) payload.bg = profile.bloodGroup;
  if (on.allergies) payload.al = nonEmpty(profile.allergies);
  if (on.conditions) payload.cc = nonEmpty(profile.conditions);
  if (on.medications) payload.med = nonEmpty(profile.medications);
  if (on.organDonor && profile.organDonor !== undefined) payload.org = profile.organDonor;
  if (on.emergencyContacts) {
    payload.ec = nonEmpty(
      profile.emergencyContacts?.map((c) => (c.relation ? { n: c.name, r: c.relation, p: c.phone } : { n: c.name, p: c.phone })),
    );
  }
  // Drop keys whose value ended up undefined so JSON.stringify output stays minimal.
  for (const key of Object.keys(payload) as (keyof TagPayload)[]) if (payload[key] === undefined) delete payload[key];
  return payload;
}

/** Returns human-readable problems; an empty list means the payload matches tag-payload.schema.json. */
export function validatePayload(p: TagPayload): string[] {
  const errors: string[] = [];
  const list = (key: 'al' | 'cc' | 'med', maxItems: number, maxLen: number) => {
    const value = p[key];
    if (value === undefined) return;
    if (value.length > maxItems) errors.push(`${key}: at most ${maxItems} items`);
    value.forEach((item, i) => item.length > maxLen && errors.push(`${key}[${i}]: at most ${maxLen} characters`));
  };
  if (p.v !== PAYLOAD_VERSION) errors.push('v: unsupported version');
  if (!TAG_ID_PATTERN.test(p.tid)) errors.push('tid: must be 16 base64url characters');
  if (!p.n || p.n.length > 60) errors.push('n: name is required, at most 60 characters');
  if (p.dob !== undefined && !/^\d{4}-\d{2}-\d{2}$/.test(p.dob)) errors.push('dob: must be YYYY-MM-DD');
  if (p.bg !== undefined && !BLOOD_GROUPS.includes(p.bg)) errors.push('bg: unknown blood group');
  list('al', 8, 40);
  list('cc', 6, 40);
  list('med', 6, 50);
  if (p.ec !== undefined) {
    if (p.ec.length > 3) errors.push('ec: at most 3 contacts');
    p.ec.forEach((c, i) => {
      if (!c.n || c.n.length > 40) errors.push(`ec[${i}].n: name is required, at most 40 characters`);
      if (!/^\+[0-9]{8,15}$/.test(c.p)) errors.push(`ec[${i}].p: phone must be E.164, e.g. +919876543210`);
    });
  }
  if (!Number.isInteger(p.ts)) errors.push('ts: must be unix seconds');
  return errors;
}

export function encodePayloadJson(p: TagPayload): Buffer {
  return Buffer.from(JSON.stringify(p), 'utf8');
}
