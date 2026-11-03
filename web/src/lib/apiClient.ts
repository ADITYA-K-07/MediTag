"use client";

import { auth } from "./firebase/client";

export class ApiCallError extends Error {
  constructor(
    message: string,
    readonly status: number,
  ) {
    super(message);
  }
}

/** POST to our own /api routes with the signed-in user's Firebase ID token. */
export async function callApi<T>(path: string, body: object = {}): Promise<T> {
  const user = auth().currentUser;
  if (!user) throw new ApiCallError("Please log in.", 401);
  const res = await fetch(path, {
    method: "POST",
    headers: { "content-type": "application/json", authorization: `Bearer ${await user.getIdToken()}` },
    body: JSON.stringify(body),
  });
  const data = await res.json().catch(() => ({}));
  if (!res.ok) throw new ApiCallError(data.error ?? "Something went wrong. Please try again.", res.status);
  return data as T;
}
