import { TAG_ID_PATTERN } from "@/server/core/ids";
import { handle, requireString, requireUser } from "@/server/http";
import { prepareTagRewrite } from "@/server/tags";

/** POST /api/tags/:tagId/rewrite → fresh signed payload + the tag's password so the app can update it. */
export const POST = handle(async (req, ctx: RouteContext<"/api/tags/[tagId]/rewrite">) => {
  const user = await requireUser(req);
  return prepareTagRewrite(user.uid, requireString((await ctx.params).tagId, "tagId", TAG_ID_PATTERN));
});
