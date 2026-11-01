import { handle, readJson, requireString, requireUser } from "@/server/http";
import { prepareTagWrite } from "@/server/tags";

/** POST /api/tags {label} → signed payload + write password for a new tag (citizen, app only). */
export const POST = handle(async (req) => {
  const user = await requireUser(req);
  const body = await readJson(req);
  return prepareTagWrite(user.uid, requireString(body.label, "label"));
});
