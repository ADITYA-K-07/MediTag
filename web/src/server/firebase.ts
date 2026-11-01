import "server-only";
import { cert, getApps, initializeApp } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { getFirestore } from "firebase-admin/firestore";
import { env } from "./env";

// Firebase Admin SDK on the Spark (free) plan: Auth and Firestore only. Initialised lazily so pages
// that don't need it (and demo mode) never require credentials.
function app() {
  return getApps()[0] ?? initializeApp({ credential: cert(env.serviceAccount()) });
}

export const db = () => getFirestore(app());
export const adminAuth = () => getAuth(app());
