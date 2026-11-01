import { TAG_ID_PATTERN } from "@/server/core/ids";
import { requestPatientAccess } from "@/server/doctors";
import { badRequest, handle, readJson, requireString, requireUser } from "@/server/http";

/** POST /api/access {tagId, nfcUid, tappedAt} → 24-hour access to the full record (verified doctor, after a tap). */
export const POST = handle(async (req) => {
  const user = await requireUser(req);
  const body = await readJson(req);
  const tappedAt = Number(body.tappedAt);
  if (!Number.isFinite(tappedAt)) throw badRequest("tappedAt is invalid.");
  return requestPatientAccess(user, requireString(body.tagId, "tagId", TAG_ID_PATTERN), requireString(body.nfcUid, "nfcUid"), tappedAt);
});
