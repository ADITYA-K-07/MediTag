import { TAG_ID_PATTERN } from "@/server/core/ids";
import { handle, readJson, requireString, requireUser } from "@/server/http";
import { confirmTagWrite } from "@/server/tags";

/** POST /api/tags/:tagId/confirm {nfcUid} → the app wrote and read back the tag; it becomes active. */
export const POST = handle(async (req, ctx: RouteContext<"/api/tags/[tagId]/confirm">) => {
  const user = await requireUser(req);
  const tagId = requireString((await ctx.params).tagId, "tagId", TAG_ID_PATTERN);
  const body = await readJson(req);
  return confirmTagWrite(user.uid, tagId, requireString(body.nfcUid, "nfcUid"));
});
