"use client";

import { collection, limit, onSnapshot, orderBy, query, where, type Query, type Timestamp } from "firebase/firestore";
import Link from "next/link";
import { useEffect, useState } from "react";
import { useSession } from "@/components/auth/AuthProvider";
import { Icon } from "@/components/Icon";
import { callApi } from "@/lib/apiClient";
import { db } from "@/lib/firebase/client";
import { completeness, useEmergencyProfile } from "@/lib/profile";

interface TagRow {
  id: string;
  label: string;
  status: "pending" | "active" | "revoked";
  writtenAt?: Timestamp;
}

interface Notification {
  id: string;
  title: string;
  body: string;
  createdAt?: Timestamp;
}

const STATUS = {
  active: { label: "Active", cls: "bg-mint-pastel text-mint" },
  pending: { label: "Not finished", cls: "bg-peach-pastel text-peach" },
  revoked: { label: "Revoked", cls: "bg-line text-ink-muted" },
} as const;

const fmt = (t?: Timestamp) => (t ? t.toDate().toLocaleString("en-IN", { day: "numeric", month: "short", hour: "2-digit", minute: "2-digit" }) : "");

/** Live query results; `build` must be a module-level function so it stays stable between renders. */
function useLive<T>(uid: string | undefined, build: (uid: string) => Query) {
  const [rows, setRows] = useState<T[] | null>(null);
  useEffect(() => {
    if (!uid) return;
    return onSnapshot(build(uid), (snap) => setRows(snap.docs.map((d) => ({ id: d.id, ...d.data() }) as T)));
  }, [uid, build]);
  return rows;
}

const tagsQuery = (uid: string) => query(collection(db(), "tags"), where("ownerUid", "==", uid));
const notificationsQuery = (uid: string) => query(collection(db(), "users", uid, "notifications"), orderBy("createdAt", "desc"), limit(5));

export function CitizenHome() {
  const { user } = useSession();
  const { profile, exists } = useEmergencyProfile(user?.uid);
  const tags = useLive<TagRow>(user?.uid, tagsQuery);
  const notifications = useLive<Notification>(user?.uid, notificationsQuery);
  const [revoking, setRevoking] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  const strength = profile ? completeness(profile) : null;
  const visibleTags = (tags ?? []).filter((t) => t.status !== "pending").sort((a, b) => a.label.localeCompare(b.label));
  const activeCount = visibleTags.filter((t) => t.status === "active").length;

  async function revoke(tag: TagRow) {
    if (!confirm(`Revoke your ${tag.label} tag? Anyone who scans it will see "This tag has been deactivated".`)) return;
    setRevoking(tag.id);
    setError(null);
    try {
      await callApi(`/api/tags/${tag.id}/revoke`);
    } catch (e) {
      setError((e as Error).message);
    } finally {
      setRevoking(null);
    }
  }

  return (
    <div className="mt-stagger flex flex-col gap-6">
      <div>
        <h1 className="font-heading text-[clamp(32px,4vw,44px)] leading-none font-extrabold tracking-[-0.04em] text-navy">Hello{profile?.name ? `, ${profile.name.split(" ")[0]}` : ""}</h1>
        <p className="mt-1 flex items-center gap-2 text-sm text-ink-muted">
          <span className="size-2 rounded-full bg-mint shadow-[0_0_0_4px_rgba(31,122,92,.16)]" /> Synced with your MediTag app
        </p>
      </div>

      {!exists && (
        <div className="flex flex-wrap items-center gap-4 rounded-[28px] bg-mint-pastel p-6 text-mint">
          <Icon name="heart" size={24} />
          <div className="flex-[1_1_260px]">
            <p className="font-bold">Start with your emergency profile</p>
            <p className="text-sm">Blood group, allergies and who to call. It takes two minutes.</p>
          </div>
          <Link href="/citizen/profile" className="mt-press flex h-11 items-center rounded-full bg-navy px-5 hover:bg-[#262A45] font-bold text-white">
            Fill it in
          </Link>
        </div>
      )}

      <div className="grid grid-cols-[repeat(auto-fit,minmax(280px,1fr))] gap-5">
        <section className="flex flex-col gap-4 rounded-[28px] bg-white p-6">
          <div className="flex items-center gap-4">
            <Ring percent={strength?.percent ?? 0} />
            <div>
              <h2 className="font-bold">Profile strength</h2>
              <p className="text-sm text-ink-muted">{strength?.missing.length ? `${strength.missing.length} item${strength.missing.length > 1 ? "s" : ""} left` : "Complete"}</p>
            </div>
          </div>
          {strength && strength.missing.length > 0 && (
            <ul className="flex flex-col gap-1.5 text-sm text-ink-muted">
              {strength.missing.map((m) => (
                <li key={m} className="flex items-center gap-2"><span className="size-4 rounded-full border-[1.5px] border-dashed border-ink-muted/60" />{m}</li>
              ))}
            </ul>
          )}
          <Link href="/citizen/profile" className="mt-auto text-sm font-semibold text-lavender">Edit emergency profile →</Link>
        </section>

        <section className="flex flex-col gap-3 rounded-[28px] bg-white p-6">
          <div className="flex items-center justify-between">
            <h2 className="font-bold">My tags</h2>
            <span className="text-sm text-ink-muted">{activeCount} of 3 active</span>
          </div>
          {tags === null ? (
            <p className="text-sm text-ink-muted">Loading…</p>
          ) : visibleTags.length === 0 ? (
            <p className="rounded-2xl bg-sky-pastel p-4 text-sm text-sky">
              No tags yet. Tags are programmed from the <b>MediTag app</b>: open it, tap <b>Program a tag</b>, and hold the tag to your phone.
            </p>
          ) : (
            <ul className="flex flex-col">
              {visibleTags.map((t) => (
                <li key={t.id} className="flex items-center gap-3 border-b border-line py-3 last:border-0">
                  <div className="flex-1">
                    <p className="font-semibold">{t.label}</p>
                    <p className="text-[12.5px] text-ink-muted">{t.writtenAt ? `Written ${fmt(t.writtenAt)}` : ""}</p>
                  </div>
                  <span className={`rounded-full px-2.5 py-1 text-xs font-bold ${STATUS[t.status].cls}`}>{STATUS[t.status].label}</span>
                  {t.status === "active" && (
                    <button onClick={() => revoke(t)} disabled={revoking === t.id} className="h-9 rounded-full border border-rose-pastel px-3 text-xs font-bold text-rose disabled:opacity-50">
                      {revoking === t.id ? "Revoking…" : "Revoke"}
                    </button>
                  )}
                </li>
              ))}
            </ul>
          )}
          {error && <p role="alert" className="rounded-xl bg-peach-pastel p-3 text-sm text-peach">{error}</p>}
        </section>
      </div>

      <section className="rounded-[28px] bg-white p-6">
        <h2 className="font-bold">Recent activity</h2>
        {notifications && notifications.length > 0 ? (
          <ul className="mt-2 flex flex-col">
            {notifications.map((n) => (
              <li key={n.id} className="flex flex-col gap-0.5 border-b border-line py-3 last:border-0">
                <span className="font-semibold">{n.title}</span>
                <span className="text-sm text-ink-muted">{n.body} · {fmt(n.createdAt)}</span>
              </li>
            ))}
          </ul>
        ) : (
          <p className="mt-2 text-sm text-ink-muted">Nothing yet. When a doctor opens your record or someone scans your tag, it shows up here.</p>
        )}
      </section>
    </div>
  );
}

function Ring({ percent }: { percent: number }) {
  const c = 2 * Math.PI * 30;
  return (
    <div className="relative size-[72px] shrink-0">
      <svg width="72" height="72" viewBox="0 0 72 72" aria-hidden="true">
        <circle cx="36" cy="36" r="30" fill="none" stroke="var(--mint-pastel)" strokeWidth="8" />
        <circle cx="36" cy="36" r="30" fill="none" stroke="var(--mint-strong)" strokeWidth="8" strokeLinecap="round" strokeDasharray={`${(percent / 100) * c} ${c}`} transform="rotate(-90 36 36)" className="transition-[stroke-dasharray] duration-700" />
      </svg>
      <span className="absolute inset-0 flex items-center justify-center font-heading text-[17px] font-extrabold text-mint">{percent}%</span>
    </div>
  );
}
