import "server-only";
import { FieldValue } from "firebase-admin/firestore";
import { audit } from "./activity";
import { MAX_ACTIVE_TAGS, TagStatus } from "./core/access";
import { newTagId, newTagPassword } from "./core/ids";
import { buildPayload, EmergencyProfile, TagPayload } from "./core/payload";
import { openSecret, sealSecret } from "./core/secrets";
import { planTagWrite, TagWriteError, TagWritePlan } from "./core/tagWrite";
import { env } from "./env";
import { db } from "./firebase";
import { badRequest, conflict, notFound } from "./http";

export interface TagDoc {
  ownerUid: string;
  label: string;
  status: TagStatus;
  nfcUid?: string;
}

/** tagSecrets/{tagId}: never readable by clients (firestore.rules). Sealed PWD (4 bytes) + PACK (2 bytes). */
interface TagSecretDoc {
  sealed: string;
}

export type TagWriteResponse = TagWritePlan & { pwd: string; pack: string };

const tags = () => db().collection("tags");
const tagSecrets = () => db().collection("tagSecrets");

async function loadProfile(uid: string): Promise<EmergencyProfile> {
  const snap = await db().collection("emergencyProfiles").doc(uid).get();
  if (!snap.exists) throw conflict("Fill in your emergency profile first.");
  return snap.data() as EmergencyProfile;
}

function plan(profile: EmergencyProfile, tagId: string): TagWritePlan {
  try {
    return planTagWrite({
      profile,
      tagId,
      baseUrl: env.publicBaseUrl(),
      signingKey: env.signingKeyPem(),
      keyId: env.signingKeyId(),
      now: Date.now(),
    });
  } catch (e) {
    if (e instanceof TagWriteError) throw badRequest(e.message, { problems: e.details });
    throw e;
  }
}

async function ownedTag(uid: string, tagId: string) {
  const ref = tags().doc(tagId);
  const tag = (await ref.get()).data() as TagDoc | undefined;
  if (!tag || tag.ownerUid !== uid) throw notFound("Tag not found.");
  return { ref, tag };
}

/** Citizen: signed payload plus a fresh write password for a new tag. The app writes and locks the tag. */
export async function prepareTagWrite(uid: string, label: string): Promise<TagWriteResponse> {
  const active = await tags().where("ownerUid", "==", uid).where("status", "==", "active").count().get();
  if (active.data().count >= MAX_ACTIVE_TAGS) {
    throw conflict(`You can have at most ${MAX_ACTIVE_TAGS} active tags. Revoke one first.`);
  }
  const tagId = newTagId();
  const writePlan = plan(await loadProfile(uid), tagId);
  const { pwd, pack } = newTagPassword();
  const batch = db().batch();
  batch.set(tags().doc(tagId), { ownerUid: uid, label, status: "pending", createdAt: FieldValue.serverTimestamp() });
  batch.set(tagSecrets().doc(tagId), { sealed: sealSecret(Buffer.concat([pwd, pack]), env.secretKey()) });
  await batch.commit();
  return { ...writePlan, pwd: pwd.toString("hex"), pack: pack.toString("hex") };
}

/** Citizen: the app read the tag back successfully, so it becomes active. */
export async function confirmTagWrite(uid: string, tagId: string, nfcUid: string) {
  const { ref, tag } = await ownedTag(uid, tagId);
  if (tag.status === "revoked") throw conflict("This tag was revoked.");
  await ref.update({ status: "active", nfcUid, writtenAt: FieldValue.serverTimestamp() });
  await audit({ actorUid: uid, action: tag.status === "pending" ? "tag.activated" : "tag.rewritten", tagId });
  return { ok: true };
}

/** Citizen: re-sign the current profile for an existing tag and return its password so the app can unlock it. */
export async function prepareTagRewrite(uid: string, tagId: string): Promise<TagWriteResponse> {
  const { tag } = await ownedTag(uid, tagId);
  if (tag.status !== "active") throw conflict("Only active tags can be updated.");
  const sealed = (await tagSecrets().doc(tagId).get()).data() as TagSecretDoc | undefined;
  if (!sealed) throw new Error(`tagSecrets/${tagId} missing`);
  const secret = openSecret(sealed.sealed, env.secretKey());
  return { ...plan(await loadProfile(uid), tagId), pwd: secret.subarray(0, 4).toString("hex"), pack: secret.subarray(4).toString("hex") };
}

/** Citizen: deactivate a lost tag, from the app or the website. */
export async function revokeTag(uid: string, tagId: string) {
  const { ref } = await ownedTag(uid, tagId);
  await ref.update({ status: "revoked", revokedAt: FieldValue.serverTimestamp() });
  await audit({ actorUid: uid, action: "tag.revoked", tagId });
  return { ok: true };
}

export type PublicEmergency =
  | { status: "active"; payload: TagPayload }
  | { status: "revoked" }
  | { status: "not-found" };

/** Anyone: Tier-1 info for /e/<tagId>, used when the phone opened the tag's URL instead of reading its record. */
export async function publicEmergencyView(tagId: string): Promise<PublicEmergency> {
  const tag = (await tags().doc(tagId).get()).data() as TagDoc | undefined;
  if (!tag || tag.status === "pending") return { status: "not-found" };
  if (tag.status === "revoked") return { status: "revoked" };
  const profile = (await db().collection("emergencyProfiles").doc(tag.ownerUid).get()).data() as EmergencyProfile | undefined;
  if (!profile) return { status: "not-found" };
  await db().collection("publicScans").add({ tagId, ownerUid: tag.ownerUid, scannedAt: FieldValue.serverTimestamp(), via: "web" });
  return { status: "active", payload: buildPayload(profile, tagId, Math.floor(Date.now() / 1000)) };
}
