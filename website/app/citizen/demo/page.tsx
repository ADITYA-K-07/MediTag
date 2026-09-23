"use client";

import { useState } from "react";
import { Check, FileHeart, HeartPulse, Pencil, Save, ShieldCheck } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { MediTagHeader } from "@/components/meditag-header";

export default function CitizenDashboard() {
  const [editing, setEditing] = useState(false);
  const [saved, setSaved] = useState(false);
  const [phone, setPhone] = useState("+91 98765 43210");
  function save() { setEditing(false); setSaved(true); window.setTimeout(() => setSaved(false), 2500); }
  return (
    <main className="dashboard-page">
      <MediTagHeader backHref="/citizen" backLabel="Sign out" />
      <div className="dashboard-shell">
        <div className="dashboard-heading"><div><p className="overline">Good morning, Aarav</p><h1>Your MediTag profile</h1><p>Keep the details people need in an emergency accurate and easy to understand.</p></div><span className="profile-live"><Check /> Profile active</span></div>
        {saved && <div className="save-toast" role="status"><Check /> Emergency profile updated</div>}
        <div className="dashboard-grid">
          <section className="dash-main">
            <div className="data-card profile-summary"><div className="summary-person"><span className="large-avatar">AS</span><div><p className="overline">Connected tag • MT-4829</p><h2>Aarav Sharma</h2><p>Last updated 12 September 2026</p></div></div><Button variant="outline" onClick={() => setEditing(!editing)}><Pencil /> {editing ? "Cancel" : "Edit profile"}</Button></div>
            <div className="data-card"><div className="dash-card-head"><div><p className="overline">Emergency details</p><h2>Shown without sign-in</h2></div><ShieldCheck /></div><div className="editable-grid"><label>Blood type<Input disabled={!editing} defaultValue="O+" /></label><label>Emergency contact<Input disabled={!editing} value={phone} onChange={(event) => setPhone(event.target.value)} /></label><label className="wide">Critical allergy<Input disabled={!editing} defaultValue="Penicillin — severe" /></label><label className="wide">Critical condition<Input disabled={!editing} defaultValue="Type 1 diabetes" /></label></div>{editing && <Button onClick={save}><Save /> Save changes</Button>}</div>
            <div className="data-card"><div className="dash-card-head"><div><p className="overline">Private record</p><h2>Clinical information</h2></div><FileHeart /></div><div className="record-counts"><span><strong>1</strong>Medication</span><span><strong>2</strong>Documents</span><span><strong>1</strong>Physician</span></div></div>
          </section>
          <aside className="dash-side"><div className="tag-status-card"><span><HeartPulse /></span><p className="overline">Your MediTag</p><h2>Ready for emergencies</h2><p>Emergency details are available through the NFC tag and printed QR.</p><div><Check /> Profile linked</div><div><Check /> Signature current</div><div><Check /> Web access active</div></div><div className="data-card"><p className="overline">Privacy</p><h2>You decide what is shared</h2><p>Only the emergency fields above are public through your secure tag code.</p></div></aside>
        </div>
      </div>
    </main>
  );
}
