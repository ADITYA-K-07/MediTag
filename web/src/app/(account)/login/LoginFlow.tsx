"use client";

import { FirebaseError } from "firebase/app";
import { RecaptchaVerifier, signInWithPhoneNumber, type ConfirmationResult } from "firebase/auth";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { useEffect, useRef, useState } from "react";
import { useSession } from "@/components/auth/AuthProvider";
import { Icon, Logo } from "@/components/Icon";
import { auth, firebaseConfigured } from "@/lib/firebase/client";

const ERRORS: Record<string, string> = {
  "auth/invalid-phone-number": "That phone number doesn't look right.",
  "auth/invalid-verification-code": "That code is wrong. Check the SMS and try again.",
  "auth/code-expired": "That code has expired. Send a new one.",
  "auth/too-many-requests": "Too many attempts. Wait a few minutes and try again.",
  "auth/quota-exceeded": "SMS limit reached for today. Try again tomorrow.",
  "auth/network-request-failed": "No internet connection. Check your signal and try again.",
};

function message(e: unknown): string {
  console.error("Phone sign-in failed", e);
  return (e instanceof FirebaseError && ERRORS[e.code]) || "Something went wrong. Please try again.";
}

/** Indian mobile numbers: 10 digits starting 6–9. */
const toE164 = (digits: string) => `+91${digits}`;
const validMobile = (digits: string) => /^[6-9]\d{9}$/.test(digits);

export function LoginFlow() {
  const router = useRouter();
  const { user, loading } = useSession();
  const [digits, setDigits] = useState("");
  const [code, setCode] = useState("");
  const [confirmation, setConfirmation] = useState<ConfirmationResult | null>(null);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const verifier = useRef<RecaptchaVerifier | null>(null);

  useEffect(() => {
    if (!loading && user) router.replace("/citizen");
  }, [loading, user, router]);

  useEffect(() => () => verifier.current?.clear(), []);

  async function sendCode(e: React.FormEvent) {
    e.preventDefault();
    if (!validMobile(digits)) return setError("Enter your 10-digit mobile number.");
    setBusy(true);
    setError(null);
    try {
      // Invisible reCAPTCHA protects the SMS endpoint from abuse; Firebase shows a challenge only if it suspects a bot.
      verifier.current ??= new RecaptchaVerifier(auth(), "recaptcha", { size: "invisible" });
      setConfirmation(await signInWithPhoneNumber(auth(), toE164(digits), verifier.current));
    } catch (err) {
      verifier.current?.clear();
      verifier.current = null;
      setError(message(err));
    } finally {
      setBusy(false);
    }
  }

  async function verifyCode(e: React.FormEvent) {
    e.preventDefault();
    if (!/^\d{6}$/.test(code)) return setError("Enter the 6-digit code.");
    setBusy(true);
    setError(null);
    try {
      await confirmation!.confirm(code);
      router.replace("/citizen");
    } catch (err) {
      setError(message(err));
      setBusy(false);
    }
  }

  if (!firebaseConfigured) {
    return <p className="rounded-2xl bg-peach-pastel p-4 text-peach">Sign-in isn&apos;t configured yet. See SETUP.md.</p>;
  }

  return (
    <div className="mt-stagger flex flex-col gap-6">
      <Link href="/" aria-label="MediTag home" className="self-start">
        <Logo />
      </Link>

      <div>
        <h1 className="font-heading text-[clamp(32px,4vw,44px)] leading-none font-extrabold tracking-[-0.04em] text-navy">{confirmation ? "Enter the code" : "Log in to MediTag"}</h1>
        <p className="mt-3 text-[17px] text-[#3D4258]">
          {confirmation ? `We sent a 6-digit code to +91 ${digits.slice(0, 5)} ${digits.slice(5)}.` : "We'll text you a code. No password needed."}
        </p>
      </div>

      {!confirmation ? (
        <form onSubmit={sendCode} className="flex flex-col gap-4">
          <label htmlFor="phone" className="text-sm font-semibold">Mobile number</label>
          <div className="flex h-14 items-center rounded-2xl bg-white focus-within:shadow-[0_0_0_3px_rgba(91,75,183,.35)]">
            <span className="border-r border-line px-4 font-semibold text-ink-muted">+91</span>
            <input
              id="phone"
              inputMode="numeric"
              autoComplete="tel-national"
              maxLength={10}
              value={digits}
              onChange={(e) => setDigits(e.target.value.replace(/\D/g, ""))}
              placeholder="98765 43210"
              className="h-full flex-1 bg-transparent px-4 text-lg tracking-wide outline-none"
            />
          </div>
          <button disabled={busy} className="mt-press h-14 rounded-full bg-navy font-bold hover:bg-[#262A45] text-white disabled:opacity-60">
            {busy ? "Sending…" : "Send code"}
          </button>
        </form>
      ) : (
        <form onSubmit={verifyCode} className="flex flex-col gap-4">
          <label htmlFor="code" className="text-sm font-semibold">6-digit code</label>
          <input
            id="code"
            inputMode="numeric"
            autoComplete="one-time-code"
            maxLength={6}
            value={code}
            onChange={(e) => setCode(e.target.value.replace(/\D/g, ""))}
            className="h-14 rounded-2xl bg-white px-4 text-center text-2xl tracking-[0.5em] outline-none focus:shadow-[0_0_0_3px_rgba(91,75,183,.35)]"
            autoFocus
          />
          <button disabled={busy} className="mt-press h-14 rounded-full bg-navy font-bold hover:bg-[#262A45] text-white disabled:opacity-60">
            {busy ? "Checking…" : "Verify and log in"}
          </button>
          <button
            type="button"
            onClick={() => {
              setConfirmation(null);
              setCode("");
              setError(null);
            }}
            className="h-11 font-semibold text-ink-muted"
          >
            Change number
          </button>
        </form>
      )}

      {error && (
        <p role="alert" className="flex items-center gap-2 rounded-2xl bg-peach-pastel px-4 py-3 text-sm font-semibold text-peach">
          <Icon name="alert" size={18} /> {error}
        </p>
      )}

      <div id="recaptcha" />
      <p className="text-center text-[12.5px] text-ink-muted">
        By continuing you agree to store your medical info with MediTag. You can download or delete it any time.
      </p>
    </div>
  );
}
