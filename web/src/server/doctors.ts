import "server-only";
import type { DecodedIdToken } from "firebase-admin/auth";
import { FieldValue, Timestamp } from "firebase-admin/firestore";
import { audit, notify } from "./activity";
import { decideAccess } from "./core/access";
import { db, adminAuth } from "./firebase";
import { forbidden } from "./http";
import type { TagDoc } from "./tags";

/** Fixed grant id so firestore.rules can look the grant up; a new tap renews it. */
export const grantId = (doctorUid: string, patientUid: string) => `${doctorUid}_${patientUid}`;

export const isVerifiedDoctor = (user: DecodedIdToken) => user.role === "doctor" && user.verified === true;

/** Verified doctor: open the full record after physically tapping the patient's tag. */
export async function requestPatientAccess(user: DecodedIdToken, tagId: string, nfcUid: string, tappedAt: number) {
  const tag = (await db().collection("tags").doc(tagId).get()).data() as TagDoc | undefined;
  const decision = decideAccess({ doctorVerified: isVerifiedDoctor(user), tag: tag ?? null, nfcUid, tappedAt, now: Date.now() });
  if (!decision.ok) {
    await audit({ actorUid: user.uid, action: "access.denied", tagId, extra: { reason: decision.reason } });
    throw forbidden("Access not allowed.", { reason: decision.reason });
  }

  const patientUid = tag!.ownerUid;
  const id = grantId(user.uid, patientUid);
  await db().collection("accessGrants").doc(id).set({
    doctorUid: user.uid,
    patientUid,
    tagId,
    grantedAt: FieldValue.serverTimestamp(),
    expiresAt: Timestamp.fromMillis(decision.expiresAt),
  });
  const doctor = (await db().collection("doctors").doc(user.uid).get()).data();
  await audit({ actorUid: user.uid, action: "access.granted", targetUid: patientUid, tagId, extra: { grantId: id } });
  await notify(patientUid, {
    kind: "record-viewed",
    title: "A doctor opened your medical record",
    body: `${doctor?.name ?? "A verified doctor"}${doctor?.hospital ? ", " + doctor.hospital : ""} tapped your ${tag!.label} tag.`,
  });
  return { grantId: id, patientUid, expiresAt: decision.expiresAt };
}

export async function hasActiveGrant(doctorUid: string, patientUid: string): Promise<boolean> {
  const grant = (await db().collection("accessGrants").doc(grantId(doctorUid, patientUid)).get()).data();
  return Boolean(grant && (grant.expiresAt as Timestamp).toMillis() > Date.now());
}

/** Admin: approve or reject a doctor's application. */
export async function reviewDoctor(admin: DecodedIdToken, doctorUid: string, approve: boolean, reason: string | null) {
  if (admin.role !== "admin") throw forbidden("Admins only.");
  await adminAuth().setCustomUserClaims(doctorUid, { role: "doctor", verified: approve });
  await db().collection("doctors").doc(doctorUid).update({
    status: approve ? "verified" : "rejected",
    rejectionReason: reason,
    reviewedBy: admin.uid,
    reviewedAt: FieldValue.serverTimestamp(),
  });
  await audit({ actorUid: admin.uid, action: approve ? "doctor.approved" : "doctor.rejected", targetUid: doctorUid, extra: { reason } });
  await notify(doctorUid, {
    kind: "verification",
    title: approve ? "You are verified on MediTag" : "Your MediTag verification needs attention",
    body: approve ? "You can now open full records after tapping a patient tag. Log out and back in to start." : `Reason: ${reason}`,
  });
  return { ok: true };
}
