"use client";

import Link from "next/link";
import { FormEvent, useState } from "react";
import { ArrowRight, BadgeCheck, ClipboardPlus, LockKeyhole, Stethoscope } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { MediTagHeader } from "@/components/meditag-header";

export default function DoctorSignIn() {
  const [message, setMessage] = useState("");
  function submit(event: FormEvent<HTMLFormElement>) { event.preventDefault(); setMessage("Clinician verification will connect to the production identity service. Use the preview workspace below for now."); }
  return (
    <main className="portal-page doctor-theme">
      <MediTagHeader backHref="/" backLabel="Back to home" />
      <div className="portal-shell">
        <section className="portal-intro"><span className="portal-glyph"><Stethoscope /></span><p className="overline">Clinician portal</p><h1>A clearer emergency picture, with permission.</h1><p>Begin with the patient’s verified emergency profile, then request protected clinical details through an auditable access flow.</p><div className="trust-list"><span><BadgeCheck /> Verified clinician identity</span><span><ClipboardPlus /> Structured clinical information</span><span><LockKeyhole /> Every protected access is logged</span></div></section>
        <section className="sign-card"><div><p className="overline">Clinical access</p><h2>Doctor sign in</h2><p>Use the clinician identity registered with MediTag.</p></div><form onSubmit={submit}><label htmlFor="clinician-id">Clinician ID</label><Input id="clinician-id" autoComplete="username" placeholder="e.g. NMC-123456" /><label htmlFor="doctor-password">Password</label><Input id="doctor-password" type="password" autoComplete="current-password" placeholder="Enter your password" /><Button type="submit" className="full-button">Verify and continue <ArrowRight /></Button>{message && <p className="pilot-note" role="status">{message}</p>}</form><div className="divider"><span>Preview</span></div><Button asChild variant="outline" className="full-button"><Link href="/doctor/demo">Open demo clinician workspace</Link></Button><p className="signup-copy">Not registered? <button type="button" onClick={() => setMessage("Clinician onboarding will be enabled with the production verification service.")}>Request verification</button></p></section>
      </div>
    </main>
  );
}
