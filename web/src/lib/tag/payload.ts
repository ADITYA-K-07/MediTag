// Mirrors functions/src/core/payload.ts and schema/tag-payload.schema.json.

export interface TagContact {
  n: string;
  r?: string;
  p: string;
}

export interface TagPayload {
  v: 1;
  tid: string;
  n: string;
  dob?: string;
  sx?: "M" | "F" | "O";
  bg?: string;
  al?: string[];
  cc?: string[];
  med?: string[];
  org?: boolean;
  ec?: TagContact[];
  ts: number;
}

export function ageFrom(dob: string | undefined, now = new Date()): number | undefined {
  if (!dob) return undefined;
  const [y, m, d] = dob.split("-").map(Number);
  if (!y || !m || !d) return undefined;
  let age = now.getFullYear() - y;
  if (now.getMonth() + 1 < m || (now.getMonth() + 1 === m && now.getDate() < d)) age--;
  return age;
}

const SEX_LABEL = { M: "Male", F: "Female", O: "Other" } as const;

export function describePerson(p: TagPayload, now = new Date()): string {
  const parts: string[] = [];
  const age = ageFrom(p.dob, now);
  if (age !== undefined) parts.push(`${age} yrs`);
  if (p.sx) parts.push(SEX_LABEL[p.sx]);
  if (p.org) parts.push("Organ donor");
  return parts.join(" · ");
}

export function initials(name: string): string {
  return name
    .split(/\s+/)
    .filter(Boolean)
    .slice(0, 2)
    .map((w) => w[0]!.toUpperCase())
    .join("");
}
