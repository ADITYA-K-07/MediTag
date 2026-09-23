"use client";

import { FormEvent, useState } from "react";
import { ArrowRight, BadgeCheck, Clock3, FileHeart, LockKeyhole, Search, ShieldCheck, Stethoscope } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { MediTagHeader } from "@/components/meditag-header";

export default function DoctorWorkspace() {
  const [code, setCode] = useState("");
  const [message, setMessage] = useState("");
  function lookup(event: FormEvent<HTMLFormElement>) { event.preventDefault(); const valid = code.toUpperCase().replace(/\s+/g, "") === "MT-4829" || code.toUpperCase().replace(/\s+/g, "") === "MT4829"; if (valid) window.location.href = "/emergency/demo"; else setMessage("No profile found. Use MT-4829 for this preview."); }
  return (
    <main className="workspace-page">
      <MediTagHeader backHref="/doctor" backLabel="Sign out" />
      <div className="workspace-shell">
        <div className="workspace-head"><div><p className="overline">Clinician workspace</p><h1>Patient access</h1><p>Signed in as Dr. Meera Iyer • NMC verified</p></div><span><BadgeCheck /> Identity verified</span></div>
        <section className="lookup-panel"><div className="lookup-copy"><span><Stethoscope /></span><div><h2>Open a patient profile</h2><p>Enter the code printed on the MediTag. Protected data requires patient authorization.</p></div></div><form onSubmit={lookup}><Input value={code} onChange={(event) => { setCode(event.target.value); setMessage(""); }} placeholder="MediTag code, e.g. MT-4829" aria-label="MediTag code" /><Button type="submit"><Search /> Find profile</Button></form>{message && <p className="field-error" role="alert">{message}</p>}</section>
        <div className="workspace-grid">
          <section><div className="workspace-section-head"><div><p className="overline">Recent access</p><h2>Patients viewed</h2></div><Button variant="outline" size="sm">View audit log</Button></div><div className="patient-row"><span className="avatar">AS</span><div><strong>Aarav Sharma</strong><p>MT-4829 • Emergency profile</p></div><span className="access-level"><ShieldCheck /> Tier 1</span><small>Today, 10:42</small><Button asChild variant="ghost" size="icon"><a href="/emergency/demo" aria-label="Open Aarav Sharma’s profile"><ArrowRight /></a></Button></div><div className="empty-row"><Clock3 /><p>No other recent patient access.</p></div></section>
          <aside><div className="data-card access-card"><LockKeyhole /><p className="overline">Protected access</p><h2>Tier 2 requires consent</h2><p>Request access from the patient or authorized representative before opening detailed records.</p><Button disabled><FileHeart /> Request access</Button></div><div className="data-card"><p className="overline">Session security</p><h2>Access is being logged</h2><p>Identity, time, patient and access level are recorded for review.</p></div></aside>
        </div>
      </div>
    </main>
  );
}
