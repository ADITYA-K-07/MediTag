"use client";

import { getApps, initializeApp } from "firebase/app";
import { getAuth } from "firebase/auth";
import { initializeFirestore, persistentLocalCache, persistentMultipleTabManager, type Firestore } from "firebase/firestore";

// Browser-side Firebase (Spark plan: Auth + Firestore). Only account pages import this, so the public
// scan and emergency pages never download the Firebase SDK.
const config = {
  apiKey: process.env.NEXT_PUBLIC_FIREBASE_API_KEY,
  authDomain: process.env.NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN,
  projectId: process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID,
  appId: process.env.NEXT_PUBLIC_FIREBASE_APP_ID,
};

export const firebaseConfigured = Boolean(config.apiKey && config.projectId);

const app = () => getApps()[0] ?? initializeApp(config);

export const auth = () => getAuth(app());

let firestore: Firestore | undefined;
/** Firestore with an offline cache: edits made without signal sync when the connection returns. */
export const db = () =>
  (firestore ??= initializeFirestore(app(), {
    localCache: persistentLocalCache({ tabManager: persistentMultipleTabManager() }),
    ignoreUndefinedProperties: true,
  }));
