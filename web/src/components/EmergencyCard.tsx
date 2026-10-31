"use client";

import { useState } from "react";
import { describePerson, initials, type TagPayload } from "@/lib/tag/payload";
import { Icon } from "./Icon";

export type Trust = "verified" | "unverified" | "server";

const formatPhone = (p: string) => (p.startsWith("+91") && p.length === 13 ? `+91 ${p.slice(3, 8)} ${p.slice(8)}` : p);

function smsLink(payload: TagPayload, lat?: number, lng?: number): string {
  const numbers = (payload.ec ?? []).map((c) => c.p).join(",");
  const where = lat !== undefined ? ` at https://maps.google.com/?q=${lat.toFixed(5)},${lng!.toFixed(5)}` : "";
  const body = `MediTag alert: ${payload.n} may need help. Their MediTag was scanned${where}. Please call back.`;
  return `sms:${numbers}?body=${encodeURIComponent(body)}`;
}

/** Tier-1 emergency card. Works offline when the payload came from the tag itself. */
export function EmergencyCard({ payload, trust, offline }: { payload: TagPayload; trust: Trust; offline: boolean }) {
  const [locating, setLocating] = useState(false);
  const [primary, ...others] = payload.ec ?? [];
  const updated = new Date(payload.ts * 1000).toLocaleDateString("en-IN", { day: "numeric", month: "short", year: "numeric" });

  // SMS works without mobile data, which matters on village roads. Push alerts come with the notify function.
  function sendLocation() {
    if (!navigator.geolocation) return void (window.location.href = smsLink(payload));
    setLocating(true);
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        setLocating(false);
        window.location.href = smsLink(payload, pos.coords.latitude, pos.coords.longitude);
      },
      () => {
        setLocating(false);
        window.location.href = smsLink(payload);
      },
      { enableHighAccuracy: true, timeout: 8000 },
    );
  }

  return (
    <div className="mt-stagger flex flex-col gap-3.5">
      {trust === "unverified" ? (
        <div className="flex items-center gap-3 rounded-2xl bg-peach-pastel px-3.5 py-3 text-peach">
          <Icon name="alert" size={22} />
          <div>
            <p className="text-sm font-bold">Unverified tag</p>
            <p className="text-[12.5px]">This info may not be genuine. Confirm at the hospital.</p>
          </div>
        </div>
      ) : (
        <div className="mt-shine flex items-center gap-3 rounded-2xl bg-mint-pastel px-3.5 py-3 text-mint">
          <Icon name="shield" size={22} />
          <div>
            <p className="text-sm font-bold">{trust === "verified" ? "Verified MediTag" : "From MediTag records"}</p>
            <p className="text-[12.5px]">{trust === "verified" ? "Signed by MediTag · info is genuine" : "Loaded securely from the MediTag server"}</p>
          </div>
          <span className={`ml-auto rounded-full px-2.5 py-1 text-xs font-semibold ${offline ? "bg-sky-pastel text-sky" : "bg-surface text-mint"}`}>
            {offline ? "Offline · from tag" : "Online"}
          </span>
        </div>
      )}

      <div className="flex items-center gap-3.5 px-0.5 py-1">
        <span className="flex size-14 shrink-0 items-center justify-center rounded-full bg-lavender-pastel text-lg font-bold text-lavender">
          {initials(payload.n)}
        </span>
        <div>
          <h1 className="font-heading text-2xl font-extrabold tracking-tight">{payload.n}</h1>
          <p className="text-[13.5px] text-ink-muted">{describePerson(payload)}</p>
        </div>
      </div>

      {payload.bg && (
        <div className="flex items-center gap-4.5 rounded-[20px] bg-rose-pastel px-5 py-4.5">
          <span className="mt-pop font-heading text-[56px] leading-none font-extrabold text-rose [animation-delay:.35s]">{payload.bg}</span>
          <div>
            <p className="text-xs font-bold tracking-[.08em] text-rose uppercase">Blood group</p>
          </div>
        </div>
      )}

      {payload.al && (
        <section className="flex flex-col gap-3 rounded-[18px] border-[1.5px] border-rose-pastel bg-surface p-4">
          <h2 className="flex items-center gap-2 text-[12.5px] font-bold tracking-[.08em] text-rose uppercase">
            <Icon name="alert" size={18} /> Allergies
          </h2>
          <ul className="flex flex-wrap gap-2">
            {payload.al.map((a) => (
              <li key={a} className="rounded-full bg-rose-pastel px-3.5 py-2 text-[14.5px] font-semibold text-rose">
                {a}
              </li>
            ))}
          </ul>
        </section>
      )}

      {(payload.cc || payload.med) && (
        <section className="flex flex-col gap-2.5 rounded-[18px] border border-line bg-surface p-4">
          <h2 className="flex items-center gap-2 text-[12.5px] font-bold tracking-[.08em] text-lavender uppercase">
            <Icon name="heart" size={18} /> Conditions &amp; medicines
          </h2>
          {payload.cc?.map((c) => (
            <p key={c} className="text-[15.5px] font-semibold">{c}</p>
          ))}
          {payload.med?.map((m) => (
            <p key={m} className="text-[13.5px] text-ink-muted">{m}</p>
          ))}
        </section>
      )}

      {primary && (
        <>
          <h2 className="mt-1 text-xs font-bold tracking-[.08em] text-ink-muted uppercase">Emergency contacts</h2>
          <a href={`tel:${primary.p}`} className="mt-press glow-rose flex h-[68px] items-center gap-3.5 rounded-[18px] bg-rose px-4.5 text-white">
            <span className="flex size-10 items-center justify-center rounded-full bg-white/20"><Icon name="phone" /></span>
            <span>
              <span className="block text-[17px] font-bold">Call {primary.r ?? primary.n}</span>
              <span className="block text-[13px]">{primary.n} · {formatPhone(primary.p)}</span>
            </span>
          </a>
          {others.map((c) => (
            <a key={c.p} href={`tel:${c.p}`} className="mt-press flex h-[68px] items-center gap-3.5 rounded-[18px] border-[1.5px] border-rose-pastel bg-surface px-4.5">
              <span className="flex size-10 items-center justify-center rounded-full bg-rose-pastel text-rose"><Icon name="phone" /></span>
              <span>
                <span className="block text-[17px] font-bold text-rose">Call {c.r ?? c.n}</span>
                <span className="block text-[13px] text-ink-muted">{c.n} · {formatPhone(c.p)}</span>
              </span>
            </a>
          ))}
        </>
      )}

      <div className="grid grid-cols-2 gap-2.5">
        <a href="tel:108" className="mt-press flex h-16 flex-col items-center justify-center rounded-[18px] bg-rose-pastel text-rose">
          <span className="text-[17px] font-extrabold">Call 108</span>
          <span className="text-xs font-semibold">Ambulance</span>
        </a>
        <a href="tel:112" className="mt-press flex h-16 flex-col items-center justify-center rounded-[18px] bg-rose-pastel text-rose">
          <span className="text-[17px] font-extrabold">Call 112</span>
          <span className="text-xs font-semibold">Emergency</span>
        </a>
      </div>

      {primary && (
        <div className="flex flex-col gap-1.5">
          <button
            onClick={sendLocation}
            disabled={locating}
            className="mt-press flex h-15 items-center justify-center gap-2.5 rounded-[18px] bg-mint-pastel text-[15.5px] font-bold text-mint disabled:opacity-70"
          >
            <Icon name="pin" />
            {locating ? "Finding your location…" : "Send my location to family"}
          </button>
          <p className="text-center text-[12.5px] text-ink-muted">Opens SMS with your GPS location. Works without mobile data.</p>
        </div>
      )}

      <div className="my-1 h-px bg-line" />
      <p className="text-center text-[12.5px] text-ink-muted">Last updated {updated}</p>
    </div>
  );
}
