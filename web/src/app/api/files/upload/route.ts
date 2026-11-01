import { createUploadUrl } from "@/server/files";
import { handle, readJson, requireString, requireUser } from "@/server/http";

/** POST /api/files/upload {fileName, contentType, size} → signed URL to upload one medical file (citizen). */
export const POST = handle(async (req) => {
  const user = await requireUser(req);
  const body = await readJson(req);
  return createUploadUrl(user.uid, requireString(body.fileName, "fileName"), requireString(body.contentType, "contentType"), Number(body.size));
});
