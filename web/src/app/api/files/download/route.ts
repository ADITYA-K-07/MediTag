import { createDownloadUrl } from "@/server/files";
import { handle, readJson, requireString, requireUser } from "@/server/http";

/** POST /api/files/download {path} → 5-minute download link (owner, or doctor with an active grant). */
export const POST = handle(async (req) => {
  const user = await requireUser(req);
  const body = await readJson(req);
  return createDownloadUrl(user, requireString(body.path, "path"));
});
