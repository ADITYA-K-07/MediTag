import { TAG_ID_PATTERN } from "@/server/core/ids";
import { handle, requireString, requireUser } from "@/server/http";
import { revokeTag } from "@/server/tags";

/** POST /api/tags/:tagId/revoke → deactivate a lost tag (citizen, app or website). */
export const POST = handle(async (req, ctx: RouteContext<"/api/tags/[tagId]/revoke">) => {
  const user = await requireUser(req);
  return revokeTag(user.uid, requireString((await ctx.params).tagId, "tagId", TAG_ID_PATTERN));
});
