"use client";

import { onIdTokenChanged, signOut as fbSignOut, type User } from "firebase/auth";
import { doc, getDoc, serverTimestamp, setDoc } from "firebase/firestore";
import { createContext, useContext, useEffect, useState } from "react";
import { auth, db, firebaseConfigured } from "@/lib/firebase/client";

export type Role = "citizen" | "doctor" | "admin";

interface Session {
  user: User | null;
  role: Role | null;
  /** True for a doctor whose registration an admin has approved. */
  verified: boolean;
  loading: boolean;
}

const SessionContext = createContext<Session>({ user: null, role: null, verified: false, loading: true });

export const useSession = () => useContext(SessionContext);

export const signOut = () => fbSignOut(auth());

/** Creates users/{uid} on first sign-in. firestore.rules only allow a client to create itself as a citizen. */
async function ensureUserDoc(user: User) {
  const ref = doc(db(), "users", user.uid);
  if ((await getDoc(ref)).exists()) return;
  await setDoc(ref, { role: "citizen", phone: user.phoneNumber ?? null, email: user.email ?? null, createdAt: serverTimestamp() });
}

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [session, setSession] = useState<Session>({ user: null, role: null, verified: false, loading: firebaseConfigured });

  useEffect(() => {
    if (!firebaseConfigured) return;
    // Roles live in custom claims (set by the admin API), so read them from the ID token.
    return onIdTokenChanged(auth(), async (user) => {
      if (!user) return setSession({ user: null, role: null, verified: false, loading: false });
      await ensureUserDoc(user).catch((e) => console.error("Could not create user profile", e));
      const { claims } = await user.getIdTokenResult();
      setSession({ user, role: (claims.role as Role) ?? "citizen", verified: claims.verified === true, loading: false });
    });
  }, []);

  return <SessionContext value={session}>{children}</SessionContext>;
}
