"use client";

import Link from "next/link";
import { FormEvent, useEffect, useState } from "react";
import { ArrowRight, Check, HeartPulse, LockKeyhole, ScanLine, ShieldCheck, Stethoscope, UserRound } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { MediTagHeader } from "@/components/meditag-header";

export default function Home() {
  const [code, setCode] = useState("");
  const [message, setMessage] = useState("");

  useEffect(() => {
    const context = (document as Document & { modelContext?: { registerTool?: (tool: unknown, options?: { signal?: AbortSignal }) => void | Promise<void> } }).modelContext;
    if (!context?.registerTool) return;
    const lifecycle = new AbortController();
    void Promise.resolve(context.registerTool({
      name: "open_emergency_profile",
      title: "Open MediTag emergency profile",
      description: "Validate a MediTag access code and open its approved emergency profile.",
      inputSchema: { type: "object", properties: { code: { type: "string", description: "The code printed on the MediTag, for example MT-4829." } }, required: ["code"], additionalProperties: false },
      annotations: { readOnlyHint: true, untrustedContentHint: false },
      execute(input: unknown) {
        const value = typeof input === "object" && input !== null && "code" in input ? String((input as { code: unknown }).code).trim().toUpperCase().replace(/\s+/g, "") : "";
        if (value !== "MT-4829" && value !== "MT4829") throw new Error("MediTag code not found.");
        window.location.href = "/emergency/demo";
        return { status: "opened", profile: "MT-4829" };
      },
    }, { signal: lifecycle.signal })).catch(() => undefined);
    return () => lifecycle.abort();
  }, []);

  function openProfile(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const normalised = code.trim().toUpperCase().replace(/\s+/g, "");
    if (normalised === "MT-4829" || normalised === "MT4829") {
      window.location.href = "/emergency/demo";
      return;
    }
    setMessage("We couldn’t find that access code. Try the demo code MT-4829.");
  }

  return (
    <main>
      <MediTagHeader />

      <section className="hero">
        <div className="hero-copy">
          <div className="eyebrow"><span /> Emergency information, when it matters</div>
          <h1>One tap can tell them how to help.</h1>
          <p className="hero-lede">MediTag keeps critical medical information close—on a secure NFC tag and available on the web when installing an app is not practical.</p>
          <div className="hero-actions">
            <Button asChild size="lg"><a href="#emergency-access">Open a MediTag <ArrowRight /></a></Button>
            <Button asChild size="lg" variant="outline"><a href="#how-it-works">See how it works</a></Button>
          </div>
          <p className="hero-note"><ShieldCheck aria-hidden="true" /> Critical details are signed and checked for tampering.</p>
        </div>

        <div className="hero-visual" aria-label="Example MediTag emergency profile">
          <div className="signal signal-one" /><div className="signal signal-two" />
          <div className="profile-card">
            <div className="profile-topline"><span className="verified"><Check aria-hidden="true" /> Verified profile</span><span className="profile-id">MT • 4829</span></div>
            <div className="person-row"><div className="avatar">AS</div><div><p className="overline">Emergency profile</p><h2>Aarav Sharma</h2></div></div>
            <div className="vitals-grid"><div className="blood-tile"><span>Blood type</span><strong>O+</strong></div><div className="contact-tile"><span>Emergency contact</span><strong>Priya • +91 98••• ••210</strong></div></div>
            <div className="profile-section"><p className="overline">Critical alerts</p><div className="tags"><span className="tag tag-red">Severe penicillin allergy</span><span className="tag tag-amber">Type 1 diabetes</span></div></div>
            <div className="profile-footer"><LockKeyhole aria-hidden="true" /><span>Full record stays private</span><ArrowRight aria-hidden="true" /></div>
          </div>
          <div className="tap-chip"><ScanLine aria-hidden="true" /><span><strong>Tap or scan</strong>Works with the tag or printed QR</span></div>
        </div>
      </section>

      <section className="access-wrap" id="emergency-access">
        <div className="access-copy"><p className="overline">Need to help someone now?</p><h2>Open an emergency profile</h2><p>Enter the short code printed beside the QR on their MediTag. No account is needed for approved emergency details.</p></div>
        <form className="access-form" onSubmit={openProfile} noValidate>
          <label htmlFor="access-code">MediTag access code</label>
          <div className="field-row"><Input id="access-code" value={code} onChange={(event) => { setCode(event.target.value); setMessage(""); }} placeholder="e.g. MT-4829" autoComplete="off" aria-describedby="code-help code-error" /><Button type="submit">View profile <ArrowRight /></Button></div>
          <p id="code-help" className="field-help">For this preview, use <button type="button" onClick={() => setCode("MT-4829")}>MT-4829</button>.</p>
          {message && <p id="code-error" className="field-error" role="alert">{message}</p>}
        </form>
      </section>

      <section className="audience-strip" aria-label="MediTag portals">
        <Link href="/citizen"><span className="icon-box blue"><UserRound /></span><span><strong>For citizens</strong><small>Create and manage your medical profile</small></span><ArrowRight /></Link>
        <Link href="/doctor"><span className="icon-box purple"><Stethoscope /></span><span><strong>For doctors</strong><small>Request authorized clinical information</small></span><ArrowRight /></Link>
      </section>

      <section className="how-section" id="how-it-works">
        <div className="section-heading"><p className="overline">Simple in an emergency</p><h2>Two ways in. One trusted profile.</h2><p>The tag stays useful when the app is not installed, while the native reader preserves offline access when the internet is unavailable.</p></div>
        <div className="steps-grid">
          <article><span>01</span><ScanLine /><h3>Tap or scan</h3><p>Tap the NFC tag with the MediTag app, or scan the printed QR with any phone camera.</p></article>
          <article><span>02</span><ShieldCheck /><h3>Check authenticity</h3><p>The app verifies signed tag data offline. Web profiles are checked by the MediTag service.</p></article>
          <article><span>03</span><HeartPulse /><h3>See what matters</h3><p>Approved allergies, conditions, blood type and an emergency contact appear first.</p></article>
        </div>
      </section>

      <section className="privacy-section" id="privacy">
        <div className="privacy-icon"><LockKeyhole /></div>
        <div><p className="overline">Privacy by design</p><h2>Emergency details are accessible. Your full history is not.</h2></div>
        <p>Only the information a citizen approves for emergencies appears without sign-in. Detailed records require authenticated, authorized access and should always be auditable.</p>
      </section>

      <footer><Link className="brand" href="/"><span className="brand-mark"><HeartPulse /></span><span>MediTag</span></Link><p>Emergency medical information, close at hand.</p><span>Semester project prototype • Not a substitute for medical advice</span></footer>
    </main>
  );
}
