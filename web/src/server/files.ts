import "server-only";
import { randomUUID } from "node:crypto";
import { createClient } from "@supabase/supabase-js";
import type { DecodedIdToken } from "firebase-admin/auth";
import { audit } from "./activity";
import { hasActiveGrant, isVerifiedDoctor } from "./doctors";
import { env } from "./env";
import { badRequest, forbidden } from "./http";

// Medical files live in a PRIVATE Supabase Storage bucket (free tier). Clients never get bucket
// credentials: they get a one-off signed upload URL, and download links valid for 5 minutes.

const MAX_BYTES = 20 * 1024 * 1024;
const ALLOWED_TYPES = /^(application\/pdf|image\/(jpeg|png|webp|heic))$/;
const DOWNLOAD_SECONDS = 5 * 60;

const bucket = () =>
  createClient(env.supabaseUrl(), env.supabaseServiceKey(), { auth: { persistSession: false } }).storage.from(env.supabaseBucket());

/** Citizen: get a signed URL to upload one file into their own folder. Store the returned path on the record. */
export async function createUploadUrl(uid: string, fileName: string, contentType: string, size: number) {
  if (!ALLOWED_TYPES.test(contentType)) throw badRequest("Only PDF and image files can be uploaded.");
  if (!Number.isInteger(size) || size <= 0 || size > MAX_BYTES) throw badRequest("Files must be under 20 MB.");
  const safeName = fileName.replace(/[^A-Za-z0-9._-]+/g, "_").slice(-80) || "file";
  const path = `${uid}/${randomUUID()}-${safeName}`;
  const { data, error } = await bucket().createSignedUploadUrl(path);
  if (error) throw error;
  return { path: data.path, signedUrl: data.signedUrl };
}

/** Owner, or a verified doctor with an active grant for this patient: a short-lived download link. */
export async function createDownloadUrl(user: DecodedIdToken, path: string) {
  const patientUid = path.split("/")[0];
  if (!patientUid || path.includes("..")) throw badRequest("Invalid file path.");
  const isOwner = user.uid === patientUid;
  if (!isOwner && !(isVerifiedDoctor(user) && (await hasActiveGrant(user.uid, patientUid)))) {
    throw forbidden("You don't have access to this file.");
  }
  const { data, error } = await bucket().createSignedUrl(path, DOWNLOAD_SECONDS);
  if (error) throw error;
  if (!isOwner) await audit({ actorUid: user.uid, action: "file.viewed", targetUid: patientUid, extra: { path } });
  return { url: data.signedUrl, expiresInSeconds: DOWNLOAD_SECONDS };
}
