import "server-only";
import type { DecodedIdToken } from "firebase-admin/auth";
import { serverConfigured } from "./env";
import { adminAuth } from "./firebase";

/** An error safe to show the caller, with an HTTP status and optional machine-readable details. */
export class ApiError extends Error {
  constructor(
    readonly status: number,
    message: string,
    readonly details?: Record<string, unknown>,
  ) {
    super(message);
  }
}

export const badRequest = (message: string, details?: Record<string, unknown>) => new ApiError(400, message, details);
export const forbidden = (message: string, details?: Record<string, unknown>) => new ApiError(403, message, details);
export const notFound = (message: string) => new ApiError(404, message);
export const conflict = (message: string, details?: Record<string, unknown>) => new ApiError(409, message, details);

/** Wraps a route handler: turns ApiError into a JSON error response and hides anything unexpected. */
export function handle<Ctx>(fn: (req: Request, ctx: Ctx) => Promise<unknown>) {
  return async (req: Request, ctx: Ctx): Promise<Response> => {
    if (!serverConfigured) {
      return Response.json({ error: "The MediTag server isn't configured yet (demo mode). See SETUP.md." }, { status: 503 });
    }
    try {
      return Response.json(await fn(req, ctx));
    } catch (e) {
      if (e instanceof ApiError) return Response.json({ error: e.message, ...e.details }, { status: e.status });
      console.error(e);
      return Response.json({ error: "Something went wrong. Please try again." }, { status: 500 });
    }
  };
}

/** Verifies the Firebase ID token sent by the app or website as `Authorization: Bearer <token>`. */
export async function requireUser(req: Request): Promise<DecodedIdToken> {
  const token = req.headers.get("authorization")?.match(/^Bearer (.+)$/)?.[1];
  if (!token) throw new ApiError(401, "Please log in.");
  try {
    return await adminAuth().verifyIdToken(token, true);
  } catch {
    throw new ApiError(401, "Your session has expired. Please log in again.");
  }
}

export async function readJson(req: Request): Promise<Record<string, unknown>> {
  try {
    const body = await req.json();
    if (body && typeof body === "object" && !Array.isArray(body)) return body;
  } catch {}
  throw badRequest("Request body must be a JSON object.");
}

export function requireString(value: unknown, field: string, pattern?: RegExp): string {
  if (typeof value !== "string" || value.length === 0 || value.length > 200 || (pattern && !pattern.test(value))) {
    throw badRequest(`${field} is invalid.`);
  }
  return value;
}
