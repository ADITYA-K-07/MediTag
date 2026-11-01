import "server-only";
import { connection } from "next/server";
import { TAG_ID_PATTERN } from "@/server/core/ids";
import { serverConfigured } from "@/server/env";
import { publicEmergencyView } from "@/server/tags";
import { DEMO_TAG_ID, demoPayload } from "./demo";
import type { TagPayload } from "./tag/payload";

export type PublicEmergency =
  | { status: "active"; payload: TagPayload }
  | { status: "revoked" }
  | { status: "not-found" }
  | { status: "unavailable" };

/**
 * Tier-1 info for /e/<tagId>, used when the phone opened the tag's URL instead of reading its record
 * (iPhone, QR code). Reads Firestore directly through the Admin SDK; falls back to the demo tag when the
 * server isn't configured (see SETUP.md).
 */
export async function getPublicEmergency(tagId: string): Promise<PublicEmergency> {
  if (!TAG_ID_PATTERN.test(tagId)) return { status: "not-found" };
  if (!serverConfigured) return tagId === DEMO_TAG_ID ? { status: "active", payload: demoPayload } : { status: "not-found" };
  // Always read live data at request time: a revoked tag must stop working immediately.
  await connection();
  try {
    return await publicEmergencyView(tagId);
  } catch (e) {
    console.error(e);
    return { status: "unavailable" };
  }
}
