// MediTag Cloud Functions. Business rules live in ./core (pure, unit-tested); this file wires them to Firebase.
import { initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { FieldValue, getFirestore, Timestamp } from 'firebase-admin/firestore';
import { defineSecret, defineString } from 'firebase-functions/params';
import { CallableRequest, HttpsError, onCall } from 'firebase-functions/v2/https';
import { decideAccess, MAX_ACTIVE_TAGS, TagStatus } from './core/access';
import { newTagId, newTagPassword, TAG_ID_PATTERN } from './core/ids';
import { buildPayload, EmergencyProfile } from './core/payload';
import { openSecret, sealSecret } from './core/secrets';
import { planTagWrite, TagWriteError } from './core/tagWrite';

initializeApp();
const db = getFirestore();

const TAG_SIGNING_KEY = defineSecret('TAG_SIGNING_KEY'); // PKCS#8 PEM, P-256 (npm run keys)
const TAG_SECRET_KEY = defineSecret('TAG_SECRET_KEY'); // base64, 32 bytes, encrypts tag passwords
const TAG_SIGNING_KEY_ID = defineString('TAG_SIGNING_KEY_ID', { default: '1' });
const PUBLIC_BASE_URL = defineString('PUBLIC_BASE_URL', { default: 'https://meditag.app' });

const withSecrets = { secrets: [TAG_SIGNING_KEY, TAG_SECRET_KEY], enforceAppCheck: true };

interface TagDoc {
  ownerUid: string;
  label: string;
  status: TagStatus;
  nfcUid?: string;
}

/** tagSecrets/{tagId}: server-only, sealed PWD (4 bytes) + PACK (2 bytes). */
interface TagSecretDoc {
  sealed: string;
}

function requireUid(req: CallableRequest): string {
  if (!req.auth) throw new HttpsError('unauthenticated', 'Please log in.');
  return req.auth.uid;
}

function requireString(value: unknown, field: string, pattern?: RegExp): string {
  if (typeof value !== 'string' || value.length === 0 || value.length > 200 || (pattern && !pattern.test(value))) {
    throw new HttpsError('invalid-argument', `${field} is invalid.`);
  }
  return value;
}

async function audit(entry: { actorUid: string; action: string; targetUid?: string; tagId?: string; extra?: object }) {
  await db.collection('auditLogs').add({ ...entry, timestamp: FieldValue.serverTimestamp() });
}

async function notify(uid: string, notification: { kind: string; title: string; body: string }) {
  // The app and website listen to this collection; an FCM trigger can fan it out to push later.
  await db.collection('users').doc(uid).collection('notifications').add({
    ...notification,
    read: false,
    createdAt: FieldValue.serverTimestamp(),
  });
}

async function loadProfile(uid: string): Promise<EmergencyProfile> {
  const snap = await db.collection('emergencyProfiles').doc(uid).get();
  if (!snap.exists) throw new HttpsError('failed-precondition', 'Fill in your emergency profile first.');
  return snap.data() as EmergencyProfile;
}

function plan(profile: EmergencyProfile, tagId: string) {
  try {
    return planTagWrite({
      profile,
      tagId,
      baseUrl: PUBLIC_BASE_URL.value(),
      signingKey: TAG_SIGNING_KEY.value(),
      keyId: Number(TAG_SIGNING_KEY_ID.value()),
      now: Date.now(),
    });
  } catch (e) {
    if (e instanceof TagWriteError) throw new HttpsError('failed-precondition', e.message, { problems: e.details });
    throw e;
  }
}

const secretKey = () => Buffer.from(TAG_SECRET_KEY.value(), 'base64');

async function ownedTag(uid: string, tagId: string) {
  const ref = db.collection('tags').doc(tagId);
  const snap = await ref.get();
  const tag = snap.data() as TagDoc | undefined;
  if (!tag || tag.ownerUid !== uid) throw new HttpsError('not-found', 'Tag not found.');
  return { ref, tag };
}

/** Citizen: get a signed payload and a fresh write password for a new tag. The app writes and locks the tag. */
export const prepareTagWrite = onCall(withSecrets, async (req) => {
  const uid = requireUid(req);
  const label = requireString(req.data?.label, 'label');
  const active = await db.collection('tags').where('ownerUid', '==', uid).where('status', '==', 'active').count().get();
  if (active.data().count >= MAX_ACTIVE_TAGS) {
    throw new HttpsError('resource-exhausted', `You can have at most ${MAX_ACTIVE_TAGS} active tags. Revoke one first.`);
  }
  const tagId = newTagId();
  const writePlan = plan(await loadProfile(uid), tagId);
  const { pwd, pack } = newTagPassword();
  const batch = db.batch();
  batch.set(db.collection('tags').doc(tagId), { ownerUid: uid, label, status: 'pending', createdAt: FieldValue.serverTimestamp() });
  batch.set(db.collection('tagSecrets').doc(tagId), { sealed: sealSecret(Buffer.concat([pwd, pack]), secretKey()) });
  await batch.commit();
  return { ...writePlan, pwd: pwd.toString('hex'), pack: pack.toString('hex') };
});

/** Citizen: the app read the tag back successfully, so the tag becomes active. */
export const confirmTagWrite = onCall(withSecrets, async (req) => {
  const uid = requireUid(req);
  const tagId = requireString(req.data?.tagId, 'tagId', TAG_ID_PATTERN);
  const nfcUid = requireString(req.data?.nfcUid, 'nfcUid');
  const { ref, tag } = await ownedTag(uid, tagId);
  if (tag.status === 'revoked') throw new HttpsError('failed-precondition', 'This tag was revoked.');
  await ref.update({ status: 'active', nfcUid, writtenAt: FieldValue.serverTimestamp() });
  await audit({ actorUid: uid, action: tag.status === 'pending' ? 'tag.activated' : 'tag.rewritten', tagId });
  return { ok: true };
});

/** Citizen: re-sign the current profile for an existing tag and return its password so the app can unlock it. */
export const prepareTagUpdate = onCall(withSecrets, async (req) => {
  const uid = requireUid(req);
  const tagId = requireString(req.data?.tagId, 'tagId', TAG_ID_PATTERN);
  const { tag } = await ownedTag(uid, tagId);
  if (tag.status !== 'active') throw new HttpsError('failed-precondition', 'Only active tags can be updated.');
  const sealed = (await db.collection('tagSecrets').doc(tagId).get()).data() as TagSecretDoc | undefined;
  if (!sealed) throw new HttpsError('internal', 'Tag password missing.');
  const secret = openSecret(sealed.sealed, secretKey());
  return { ...plan(await loadProfile(uid), tagId), pwd: secret.subarray(0, 4).toString('hex'), pack: secret.subarray(4).toString('hex') };
});

/** Citizen: deactivate a lost tag. Works from the app or the website. */
export const revokeTag = onCall({ enforceAppCheck: true }, async (req) => {
  const uid = requireUid(req);
  const tagId = requireString(req.data?.tagId, 'tagId', TAG_ID_PATTERN);
  const { ref } = await ownedTag(uid, tagId);
  await ref.update({ status: 'revoked', revokedAt: FieldValue.serverTimestamp() });
  await audit({ actorUid: uid, action: 'tag.revoked', tagId });
  return { ok: true };
});

/** Anyone: Tier-1 info for the public /e/<tagId> page, used when the tag's own record was not read (iPhone, QR). */
export const publicEmergencyView = onCall({ enforceAppCheck: true }, async (req) => {
  const tagId = requireString(req.data?.tagId, 'tagId', TAG_ID_PATTERN);
  const snap = await db.collection('tags').doc(tagId).get();
  const tag = snap.data() as TagDoc | undefined;
  if (!tag || tag.status === 'pending') throw new HttpsError('not-found', 'Unknown tag.');
  if (tag.status === 'revoked') return { status: 'revoked' as const };
  const profile = await loadProfile(tag.ownerUid);
  await db.collection('publicScans').add({ tagId, ownerUid: tag.ownerUid, scannedAt: FieldValue.serverTimestamp(), via: 'web' });
  return { status: 'active' as const, payload: buildPayload(profile, tagId, Math.floor(Date.now() / 1000)) };
});

/** Verified doctor: open the full record after physically tapping the patient's tag. */
export const requestPatientAccess = onCall({ enforceAppCheck: true }, async (req) => {
  const doctorUid = requireUid(req);
  const tagId = requireString(req.data?.tagId, 'tagId', TAG_ID_PATTERN);
  const nfcUid = requireString(req.data?.nfcUid, 'nfcUid');
  const tappedAt = Number(req.data?.tappedAt);
  const claims = req.auth!.token;
  const tag = (await db.collection('tags').doc(tagId).get()).data() as TagDoc | undefined;

  const decision = decideAccess({
    doctorVerified: claims.role === 'doctor' && claims.verified === true,
    tag: tag ?? null,
    nfcUid,
    tappedAt,
    now: Date.now(),
  });
  if (!decision.ok) {
    await audit({ actorUid: doctorUid, action: 'access.denied', tagId, extra: { reason: decision.reason } });
    throw new HttpsError('permission-denied', 'Access not allowed.', { reason: decision.reason });
  }

  const patientUid = tag!.ownerUid;
  // Fixed id so security rules can look the grant up; a new tap renews it.
  const grant = db.collection('accessGrants').doc(`${doctorUid}_${patientUid}`);
  await grant.set({
    doctorUid,
    patientUid,
    tagId,
    grantedAt: FieldValue.serverTimestamp(),
    expiresAt: Timestamp.fromMillis(decision.expiresAt),
  });
  const doctor = (await db.collection('doctors').doc(doctorUid).get()).data();
  await audit({ actorUid: doctorUid, action: 'access.granted', targetUid: patientUid, tagId, extra: { grantId: grant.id } });
  await notify(patientUid, {
    kind: 'record-viewed',
    title: 'A doctor opened your medical record',
    body: `${doctor?.name ?? 'A verified doctor'}${doctor?.hospital ? ', ' + doctor.hospital : ''} tapped your ${tag!.label} tag.`,
  });
  return { grantId: grant.id, patientUid, expiresAt: decision.expiresAt };
});

/** Admin: approve or reject a doctor's application. */
export const reviewDoctor = onCall({ enforceAppCheck: true }, async (req) => {
  const adminUid = requireUid(req);
  if (req.auth!.token.role !== 'admin') throw new HttpsError('permission-denied', 'Admins only.');
  const doctorUid = requireString(req.data?.doctorUid, 'doctorUid');
  const approve = req.data?.approve === true;
  const reason = approve ? null : requireString(req.data?.reason, 'reason');

  await getAuth().setCustomUserClaims(doctorUid, { role: 'doctor', verified: approve });
  await db.collection('doctors').doc(doctorUid).update({
    status: approve ? 'verified' : 'rejected',
    rejectionReason: reason,
    reviewedBy: adminUid,
    reviewedAt: FieldValue.serverTimestamp(),
  });
  await audit({ actorUid: adminUid, action: approve ? 'doctor.approved' : 'doctor.rejected', targetUid: doctorUid, extra: { reason } });
  await notify(doctorUid, {
    kind: 'verification',
    title: approve ? 'You are verified on MediTag' : 'Your MediTag verification needs attention',
    body: approve ? 'You can now open full records after tapping a patient tag.' : `Reason: ${reason}`,
  });
  return { ok: true };
});
