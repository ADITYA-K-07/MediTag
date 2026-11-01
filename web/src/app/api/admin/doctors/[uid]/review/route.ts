import { reviewDoctor } from "@/server/doctors";
import { handle, readJson, requireString, requireUser } from "@/server/http";

/** POST /api/admin/doctors/:uid/review {approve, reason?} → approve or reject a doctor (admin). */
export const POST = handle(async (req, ctx: RouteContext<"/api/admin/doctors/[uid]/review">) => {
  const admin = await requireUser(req);
  const doctorUid = requireString((await ctx.params).uid, "uid");
  const body = await readJson(req);
  const approve = body.approve === true;
  return reviewDoctor(admin, doctorUid, approve, approve ? null : requireString(body.reason, "reason"));
});
