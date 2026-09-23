"use client";

import Link from "next/link";
import { FormEvent, useState } from "react";
import { ArrowRight, FileHeart, LockKeyhole, ShieldCheck, UserRound } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { MediTagHeader } from "@/components/meditag-header";

export default function CitizenSignIn() {
  const [error, setError] = useState("");
  function submit(event: FormEvent<HTMLFormElement>) { event.preventDefault(); setError("Account sign-in will connect to the production identity service. Use the preview profile below for now."); }
  return (
    <main className="portal-page">
      <MediTagHeader backHref="/" backLabel="Back to home" />
      <div className="portal-shell">
        <section className="portal-intro"><span className="portal-glyph"><UserRound /></span><p className="overline">Citizen portal</p><h1>Your medical profile, under your control.</h1><p>Keep emergency details current, choose what others may see, and manage the record connected to your MediTag.</p><div className="trust-list"><span><ShieldCheck /> You control emergency visibility</span><span><FileHeart /> One profile across tag and web</span><span><LockKeyhole /> Full records stay access-controlled</span></div></section>
        <section className="sign-card"><div><p className="overline">Welcome back</p><h2>Sign in to MediTag</h2><p>Use your registered email address or phone number.</p></div><form onSubmit={submit}><label htmlFor="citizen-id">Email or phone</label><Input id="citizen-id" type="text" autoComplete="username" placeholder="you@example.com" /><label htmlFor="citizen-password">Password</label><Input id="citizen-password" type="password" autoComplete="current-password" placeholder="Enter your password" /><div className="form-meta"><label><input type="checkbox" /> Remember me</label><button type="button">Forgot password?</button></div><Button type="submit" className="full-button">Sign in <ArrowRight /></Button>{error && <p className="pilot-note" role="status">{error}</p>}</form><div className="divider"><span>Preview</span></div><Button asChild variant="outline" className="full-button"><Link href="/citizen/demo">Open demo citizen profile</Link></Button><p className="signup-copy">New to MediTag? <button type="button" onClick={() => setError("Account registration will be enabled with the production identity service.")}>Create an account</button></p></section>
      </div>
    </main>
  );
}
