"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useEffect, useRef, useState, useSyncExternalStore } from "react";
import { EmergencyCard, type Trust } from "@/components/EmergencyCard";
import { Icon } from "@/components/Icon";
import { demoTags } from "@/lib/demo";
import { readEnvelope } from "@/lib/tag/envelope";
import { DEMO_MODE, TAG_PUBLIC_KEYS } from "@/lib/tag/keys";
import type { TagPayload } from "@/lib/tag/payload";
import { readOneTag, webNfcSupported } from "@/lib/tag/web-nfc";

type State =
  | { step: "idle" }
  | { step: "scanning" }
  | { step: "found" }
  | { step: "card"; payload: TagPayload; trust: Trust }
  | { step: "error"; message: string };

const FOUND_MS = 900;
const PLACES = ["Wallet", "Keychain", "Bracelet", "Car windscreen"];

// Web NFC support is a browser fact that never changes after load; read it without a hydration mismatch.
const useNfcSupport = () => useSyncExternalStore(() => () => {}, webNfcSupported, () => true);
const useOnline = () =>
  useSyncExternalStore(
    (notify) => {
      window.addEventListener("online", notify);
      window.addEventListener("offline", notify);
      return () => {
        window.removeEventListener("online", notify);
        window.removeEventListener("offline", notify);
      };
    },
    () => navigator.onLine,
    () => true,
  );

export function ScanFlow() {
  const router = useRouter();
  const nfc = useNfcSupport();
  const online = useOnline();
  const [state, setState] = useState<State>({ step: "idle" });
  const abort = useRef<AbortController | null>(null);
  const timer = useRef<ReturnType<typeof setTimeout>>(undefined);

  useEffect(() => () => {
    abort.current?.abort();
    clearTimeout(timer.current);
  }, []);

  async function show(envelope: Uint8Array) {
    const result = await readEnvelope(envelope, TAG_PUBLIC_KEYS);
    if (result.status === "unreadable" || !result.payload) {
      setState({ step: "error", message: "This tag's MediTag data is damaged. Look for another tag or a QR card." });
      return;
    }
    const { payload } = result;
    setState({ step: "found" });
    timer.current = setTimeout(() => setState({ step: "card", payload, trust: result.status }), FOUND_MS);
  }

  async function scan() {
    abort.current?.abort();
    abort.current = new AbortController();
    setState({ step: "scanning" });
    try {
      const tag = await readOneTag(abort.current.signal);
      abort.current.abort(); // one tag is enough; stop the reader
      if (tag.envelope) return void (await show(tag.envelope));
      const path = tag.url && new URL(tag.url).pathname;
      if (path?.startsWith("/e/")) return void router.push(path); // older tag with only a link
      setState({ step: "error", message: "This doesn't look like a MediTag." });
    } catch (e) {
      if ((e as DOMException).name === "AbortError") return;
      const denied = (e as DOMException).name === "NotAllowedError";
      setState({ step: "error", message: denied ? "Allow NFC for this site, then try again." : (e as Error).message || "Could not read the tag." });
    }
  }

  function cancel() {
    abort.current?.abort();
    clearTimeout(timer.current);
    setState({ step: "idle" });
  }

  if (state.step === "card") {
    return (
      <>
        <TopBar title="Emergency info" onBack={cancel} />
        <EmergencyCard payload={state.payload} trust={state.trust} offline={!online} />
        <button onClick={cancel} className="mt-6 h-12 rounded-full border border-line bg-surface font-semibold">Scan another tag</button>
      </>
    );
  }

  const ringing = state.step === "scanning";
  const found = state.step === "found";

  return (
    <>
      <TopBar title="Scan a MediTag" href="/" />
      <div className="flex flex-1 flex-col items-center text-center">
        <h1 className="mt-6 font-heading text-[22px] font-bold">{found ? "Tag found" : ringing ? "Ready to scan" : "Scan a MediTag"}</h1>
        <p className="mt-1.5 text-sm text-ink-muted">
          {found ? "Reading emergency info…" : nfc ? "Hold the back of your phone near the tag" : "This browser can't read NFC tags"}
        </p>

        <div className="relative my-4 flex size-[220px] items-center justify-center">
          {found ? (
            <span className="mt-pop glow-mint flex size-28 items-center justify-center rounded-full bg-mint-pastel text-mint">
              <svg width="52" height="52" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.6" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
                <path className="mt-tick" d="M20 6 9 17l-5-5" />
              </svg>
            </span>
          ) : (
            <>
              {ringing && [1, 2, 3].map((i) => <span key={i} className={`mt-ring mt-ring-${i} absolute size-[150px] rounded-full border-2 border-rose`} />)}
              <button
                onClick={ringing ? undefined : scan}
                disabled={!nfc || ringing}
                aria-label="Start scanning"
                className={`group relative flex size-[184px] items-center justify-center rounded-full disabled:cursor-default ${nfc ? "" : "opacity-50"}`}
              >
                {!ringing && nfc && <span className="mt-pulse absolute inset-0 rounded-full bg-rose-pastel" />}
                <span className="absolute inset-0 rounded-full bg-rose-pastel" />
                <span className="glow-rose relative flex size-32 items-center justify-center rounded-full bg-rose text-white transition-transform group-enabled:group-hover:scale-105 group-enabled:group-active:scale-95">
                  <Icon name="nfc" size={52} />
                </span>
              </button>
            </>
          )}
        </div>

        {state.step === "error" && <p role="alert" className="mb-4 rounded-2xl bg-peach-pastel px-4 py-3 text-sm font-semibold text-peach">{state.message}</p>}

        {nfc ? (
          <>
            <p className="text-[11.5px] font-bold tracking-[.08em] text-ink-muted uppercase">Usually found on</p>
            <ul className="mt-2.5 flex flex-wrap justify-center gap-2">
              {PLACES.map((p) => (
                <li key={p} className="rounded-full border border-line bg-surface px-3 py-1.5 text-[13px] font-medium">{p}</li>
              ))}
            </ul>
            {ringing ? (
              <button onClick={cancel} className="mt-6 h-12 px-5 font-semibold text-ink-muted">Cancel</button>
            ) : (
              <button onClick={scan} className="mt-press glow-rose mt-6 h-14 w-full rounded-full bg-rose font-bold text-white">
                {state.step === "error" ? "Try again" : "Start scanning"}
              </button>
            )}
          </>
        ) : (
          <div className="flex w-full flex-col gap-3 text-left text-sm leading-relaxed">
            <div className="rounded-2xl border border-line bg-surface p-4">
              <p className="font-bold">On an iPhone</p>
              <p className="text-ink-muted">Close this page and hold the top of your iPhone near the tag. A banner opens the person&apos;s emergency page.</p>
            </div>
            <div className="rounded-2xl border border-line bg-surface p-4">
              <p className="font-bold">On a computer or a phone without NFC</p>
              <p className="text-ink-muted">Scan the QR code on the person&apos;s MediTag wallet card with your camera.</p>
            </div>
          </div>
        )}

        {DEMO_MODE && !ringing && !found && (
          <div className="mt-8 w-full rounded-2xl bg-sky-pastel p-4 text-left text-sky">
            <p className="text-sm font-bold">Demo mode: no tag needed</p>
            <p className="mt-0.5 text-[12.5px]">Uses a test signing key. Set NEXT_PUBLIC_TAG_PUBLIC_KEYS for real tags.</p>
            <div className="mt-3 flex flex-wrap gap-2">
              <button onClick={() => show(demoTags.genuine())} className="h-11 rounded-full bg-sky px-4 text-sm font-bold text-white">Genuine tag</button>
              <button onClick={() => show(demoTags.tampered())} className="h-11 rounded-full bg-surface px-4 text-sm font-bold text-sky">Tampered tag</button>
            </div>
          </div>
        )}
      </div>
    </>
  );
}

function TopBar({ title, onBack, href }: { title: string; onBack?: () => void; href?: string }) {
  const cls = "flex size-11 items-center justify-center rounded-full border border-line bg-surface";
  return (
    <div className="flex h-16 items-center gap-2.5">
      {href ? (
        <Link href={href} aria-label="Back" className={cls}><Icon name="back" /></Link>
      ) : (
        <button onClick={onBack} aria-label="Back" className={cls}><Icon name="back" /></button>
      )}
      <span className="font-heading text-[17px] font-bold">{title}</span>
    </div>
  );
}
