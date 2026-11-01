import "server-only";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "./firebase";

export async function audit(entry: { actorUid: string; action: string; targetUid?: string; tagId?: string; extra?: object }) {
  await db().collection("auditLogs").add({ ...entry, timestamp: FieldValue.serverTimestamp() });
}

/** The app and website listen to users/{uid}/notifications in real time. */
export async function notify(uid: string, notification: { kind: string; title: string; body: string }) {
  await db().collection("users").doc(uid).collection("notifications").add({
    ...notification,
    read: false,
    createdAt: FieldValue.serverTimestamp(),
  });
}
