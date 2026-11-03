"use client";

import { doc, onSnapshot, serverTimestamp, setDoc } from "firebase/firestore";
import { useEffect, useState } from "react";
import { envelopeLength } from "@/server/core/envelope";
import { emergencyUri, NTAG216_USER_BYTES, tagBytesNeeded } from "@/server/core/ndef";
import { buildPayload, encodePayloadJson, validatePayload, type EmergencyProfile, type OnTagField, type TagPayload } from "@/server/core/payload";
import { db } from "./firebase/client";

export type { EmergencyProfile, OnTagField };

/** What goes on the tag for a brand-new profile. Conditions stay cloud-only until the citizen opts in. */
export const DEFAULT_ON_TAG: Record<OnTagField, boolean> = {
  dob: true,
  sex: false,
  bloodGroup: true,
  allergies: true,
  conditions: false,
  medications: true,
  organDonor: true,
  emergencyContacts: true,
};

export const emptyProfile = (): EmergencyProfile => ({
  name: "",
  allergies: [],
  conditions: [],
  medications: [],
  emergencyContacts: [],
  onTagFields: { ...DEFAULT_ON_TAG },
});

/** Live emergencyProfiles/{uid}. Updates instantly when the profile is edited in the app or another tab. */
export function useEmergencyProfile(uid: string | undefined) {
  const [state, setState] = useState<{ profile: EmergencyProfile | null; exists: boolean; loading: boolean }>({
    profile: null,
    exists: false,
    loading: true,
  });
  useEffect(() => {
    if (!uid) return;
    return onSnapshot(doc(db(), "emergencyProfiles", uid), (snap) =>
      setState({ profile: snap.exists() ? (snap.data() as EmergencyProfile) : emptyProfile(), exists: snap.exists(), loading: false }),
    );
  }, [uid]);
  return state;
}

/**
 * Saves the profile. The write lands in the local cache immediately and syncs when online,
 * so this resolves without waiting for the server.
 */
export function saveProfile(uid: string, profile: EmergencyProfile): Promise<void> {
  const clean = (list?: string[]) => (list ?? []).map((s) => s.trim()).filter(Boolean);
  const write = setDoc(doc(db(), "emergencyProfiles", uid), {
    ...profile,
    name: profile.name.trim(),
    allergies: clean(profile.allergies),
    conditions: clean(profile.conditions),
    medications: clean(profile.medications),
    updatedAt: serverTimestamp(),
  });
  write.catch((e) => console.error("Profile sync failed", e));
  return Promise.resolve();
}

const PREVIEW_TAG_ID = "preview_tagid_00";

export interface TagPreview {
  payload: TagPayload;
  problems: string[];
  bytesUsed: number;
  bytesTotal: number;
}

/** Exactly what a bystander would see, and how much of the NTAG216 it uses (matches the server; see tagWrite.test.ts). */
export function previewTag(profile: EmergencyProfile, baseUrl: string): TagPreview {
  const payload = buildPayload(profile, PREVIEW_TAG_ID, Math.floor(Date.now() / 1000));
  const json = encodePayloadJson(payload);
  return {
    payload,
    problems: validatePayload(payload).filter((p) => !p.startsWith("tid")),
    bytesUsed: tagBytesNeeded({ uri: emergencyUri(baseUrl, PREVIEW_TAG_ID), envelopeLength: envelopeLength(json.length) }),
    bytesTotal: NTAG216_USER_BYTES,
  };
}

/** Rough profile strength for the dashboard ring. */
export function completeness(p: EmergencyProfile): { percent: number; missing: string[] } {
  const checks: [boolean, string][] = [
    [Boolean(p.name.trim()), "Name"],
    [Boolean(p.dob), "Date of birth"],
    [Boolean(p.bloodGroup), "Blood group"],
    [(p.allergies?.length ?? 0) > 0, "Allergies (or 'None known')"],
    [(p.medications?.length ?? 0) > 0 || (p.conditions?.length ?? 0) > 0, "Conditions or medicines"],
    [(p.emergencyContacts?.length ?? 0) > 0, "An emergency contact"],
  ];
  return {
    percent: Math.round((checks.filter(([ok]) => ok).length / checks.length) * 100),
    missing: checks.filter(([ok]) => !ok).map(([, label]) => label),
  };
}
