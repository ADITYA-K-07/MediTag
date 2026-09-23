"use client";

import Link from "next/link";
import { Activity, CalendarClock, Check, HeartPulse, LockKeyhole, Phone, Pill, Printer, ShieldCheck, Stethoscope, TriangleAlert } from "lucide-react";
import { Button } from "@/components/ui/button";
import { MediTagHeader } from "@/components/meditag-header";

export default function EmergencyProfile() {
  return (
    <main className="profile-page">
      <MediTagHeader backHref="/" backLabel="Enter another code" />
      <div className="record-shell">
        <div className="record-status" role="status"><span><Check /></span><div><strong>Verified web profile</strong><p>Checked by MediTag • Updated 12 September 2026</p></div><ShieldCheck /></div>

        <div className="record-heading">
          <div><p className="overline">Emergency profile • MT-4829</p><h1>Aarav Sharma</h1><p>Age 24 • Male • English, Hindi</p></div>
          <div className="record-actions"><Button variant="outline" onClick={() => window.print()}><Printer /> Print</Button><Button asChild><a href="tel:+919876543210"><Phone /> Call emergency contact</a></Button></div>
        </div>

        <section className="critical-banner"><TriangleAlert /><div><span>Severe allergy</span><strong>Penicillin</strong><p>Risk of anaphylaxis. Avoid penicillin-class antibiotics.</p></div></section>

        <div className="record-grid">
          <section className="record-main">
            <div className="data-card essentials-card">
              <div className="blood-block"><span>Blood type</span><strong>O+</strong></div>
              <div className="data-list"><div><span>Date of birth</span><strong>17 May 2002</strong></div><div><span>Primary language</span><strong>Hindi</strong></div><div><span>Organ donor</span><strong>Not specified</strong></div></div>
            </div>

            <div className="data-card"><div className="card-title"><Activity /><div><p className="overline">Known conditions</p><h2>Critical medical information</h2></div></div><div className="condition-row"><span className="condition-icon amber"><Activity /></span><div><strong>Type 1 diabetes</strong><p>Uses continuous glucose monitoring and insulin.</p></div></div></div>

            <div className="data-card"><div className="card-title"><Pill /><div><p className="overline">Current medication</p><h2>Medication to know</h2></div></div><div className="med-row"><div><strong>Insulin lispro</strong><p>As directed with meals</p></div><span>Active</span></div></div>

            <div className="data-card locked-card"><LockKeyhole /><div><h2>Detailed health record is protected</h2><p>Clinical history, documents and physician notes require authorized clinician access.</p></div><Button asChild variant="outline"><Link href="/doctor">Doctor access</Link></Button></div>
          </section>

          <aside className="record-side">
            <div className="data-card contact-card"><div className="card-title"><Phone /><div><p className="overline">Primary contact</p><h2>Priya Sharma</h2></div></div><p>Sister • Speaks English and Hindi</p><Button asChild><a href="tel:+919876543210"><Phone /> +91 98765 43210</a></Button></div>
            <div className="data-card"><div className="card-title"><Stethoscope /><div><p className="overline">Primary physician</p><h2>Dr. Meera Iyer</h2></div></div><p>Endocrinology<br />City Care Clinic, Bengaluru</p></div>
            <div className="data-card quiet-card"><CalendarClock /><div><strong>Profile freshness</strong><p>Last confirmed by the citizen 3 days ago.</p></div></div>
          </aside>
        </div>
        <p className="medical-note"><HeartPulse /> In an emergency, follow local protocols and contact emergency services. This profile supports—but does not replace—clinical judgment.</p>
      </div>
    </main>
  );
}
