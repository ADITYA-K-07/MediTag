"use client";

import { useMemo, useState } from "react";
import { useSession } from "@/components/auth/AuthProvider";
import { EmergencyCard } from "@/components/EmergencyCard";
import { Icon } from "@/components/Icon";
import { previewTag, saveProfile, useEmergencyProfile, type EmergencyProfile, type OnTagField } from "@/lib/profile";
import { BLOOD_GROUPS, type BloodGroup } from "@/server/core/payload";

type Contact = NonNullable<EmergencyProfile["emergencyContacts"]>[number];

const SEXES = [
  { value: "M", label: "Male" },
  { value: "F", label: "Female" },
  { value: "O", label: "Other" },
] as const;

export function ProfileEditor() {
  const { user } = useSession();
  const { profile: stored, exists, loading } = useEmergencyProfile(user?.uid);
  // Only unsaved edits live here. With none, the form shows the live stored profile, so an edit made
  // in the app appears instantly, and a remote change never overwrites what you're typing.
  const [edits, setEdits] = useState<EmergencyProfile | null>(null);
  const [savedAt, setSavedAt] = useState<number | null>(null);
  const draft = edits ?? stored;
  const dirty = edits !== null;

  const preview = useMemo(() => (draft ? previewTag(draft, window.location.origin) : null), [draft]);

  if (loading || !draft || !preview) return <p className="py-10 text-ink-muted">Loading your profile…</p>;

  const update = (patch: Partial<EmergencyProfile>) => {
    setEdits({ ...draft, ...patch });
    setSavedAt(null);
  };
  const onTag = (field: OnTagField) => draft.onTagFields?.[field] === true;
  const setOnTag = (field: OnTagField, value: boolean) => update({ onTagFields: { ...draft.onTagFields, [field]: value } });

  const tooBig = preview.bytesUsed > preview.bytesTotal;
  // Contacts are checked even when they're cloud-only: doctors call them too.
  const badContact = (draft.emergencyContacts ?? []).some((c) => !c.name.trim() || !/^\+91[6-9]\d{9}$/.test(c.phone));
  const canSave = draft.name.trim().length > 0 && preview.problems.length === 0 && !tooBig && !badContact;

  async function save() {
    await saveProfile(user!.uid, draft!);
    setEdits(null);
    setSavedAt(Date.now());
  }

  return (
    <div className="flex flex-wrap items-start gap-8">
      <section className="mt-stagger flex min-w-0 flex-[1_1_480px] flex-col gap-5">
        <div>
          <h1 className="font-heading text-[clamp(32px,4vw,44px)] leading-none font-extrabold tracking-[-0.04em] text-navy">Emergency profile</h1>
          <p className="mt-1.5 text-ink-muted">
            Fields marked <b className="text-sky">On tag</b> can be read by anyone who scans your MediTag, even offline. Everything
            else is for verified doctors only.
          </p>
        </div>

        <Card title="About you">
          <Field label="Full name" htmlFor="name">
            <input id="name" value={draft.name} onChange={(e) => update({ name: e.target.value })} maxLength={60} className={inputCls} placeholder="As on your ID" />
          </Field>
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
            <Field label="Date of birth" htmlFor="dob" onTag={onTag("dob")} setOnTag={(v) => setOnTag("dob", v)}>
              <input id="dob" type="date" value={draft.dob ?? ""} max={new Date().toISOString().slice(0, 10)} onChange={(e) => update({ dob: e.target.value || undefined })} className={inputCls} />
            </Field>
            <Field label="Sex" onTag={onTag("sex")} setOnTag={(v) => setOnTag("sex", v)}>
              <Choices options={SEXES} value={draft.sex} onChange={(sex) => update({ sex })} />
            </Field>
          </div>
          <label className="flex items-center justify-between gap-3 rounded-xl border border-line px-4 py-3">
            <span className="font-semibold">I&apos;m a registered organ donor</span>
            <span className="flex items-center gap-3">
              <OnTagSwitch value={onTag("organDonor")} onChange={(v) => setOnTag("organDonor", v)} />
              <input type="checkbox" checked={draft.organDonor ?? false} onChange={(e) => update({ organDonor: e.target.checked })} className="size-5 accent-[var(--mint-strong)]" />
            </span>
          </label>
        </Card>

        <Card title="Blood group" onTag={onTag("bloodGroup")} setOnTag={(v) => setOnTag("bloodGroup", v)}>
          <Choices
            options={BLOOD_GROUPS.map((g) => ({ value: g, label: g }))}
            value={draft.bloodGroup}
            onChange={(bloodGroup) => update({ bloodGroup: bloodGroup as BloodGroup })}
            tone="rose"
          />
        </Card>

        <Card title="Allergies" hint="Medicines, foods, latex… Add “None known” if you have none." onTag={onTag("allergies")} setOnTag={(v) => setOnTag("allergies", v)}>
          <ListInput items={draft.allergies ?? []} onChange={(allergies) => update({ allergies })} max={8} maxLength={40} placeholder="e.g. Penicillin" tone="rose" />
        </Card>

        <Card title="Medical conditions" hint="Off the tag by default. Turn it on for conditions a first responder must know, like diabetes or epilepsy." onTag={onTag("conditions")} setOnTag={(v) => setOnTag("conditions", v)}>
          <ListInput items={draft.conditions ?? []} onChange={(conditions) => update({ conditions })} max={6} maxLength={40} placeholder="e.g. Type 1 Diabetes" tone="lavender" />
        </Card>

        <Card title="Current medicines" onTag={onTag("medications")} setOnTag={(v) => setOnTag("medications", v)}>
          <ListInput items={draft.medications ?? []} onChange={(medications) => update({ medications })} max={6} maxLength={50} placeholder="e.g. Insulin glargine 20 units at night" tone="lavender" />
        </Card>

        <Card title="Emergency contacts" hint="Up to 3. The first one gets the big Call button." onTag={onTag("emergencyContacts")} setOnTag={(v) => setOnTag("emergencyContacts", v)}>
          <Contacts contacts={draft.emergencyContacts ?? []} onChange={(emergencyContacts) => update({ emergencyContacts })} />
        </Card>

        <div className="sticky bottom-0 -mx-5 flex flex-wrap items-center gap-3 bg-white px-5 py-4 shadow-[0_-12px_30px_-18px_rgba(23,26,46,.35)] sm:bottom-4 sm:mx-0 sm:rounded-[24px]">
          <button onClick={save} disabled={!canSave || !dirty} className="mt-press h-12 rounded-full bg-navy px-7 hover:bg-[#262A45] font-bold text-white disabled:opacity-50 disabled:shadow-none">
            {exists ? "Save changes" : "Save profile"}
          </button>
          <p className="text-sm text-ink-muted" role="status">
            {!draft.name.trim()
              ? "Add your name to save."
              : badContact
                ? "Each contact needs a name and a 10-digit mobile number."
                : preview.problems.length
                ? "Fix the problems listed beside the preview to save."
                : tooBig
                  ? "Too much for one tag. Move something off the tag."
                  : savedAt
                    ? "Saved. Your app updates automatically."
                    : dirty
                      ? "Unsaved changes"
                      : "All changes saved"}
          </p>
        </div>
      </section>

      <aside className="flex min-w-0 flex-[1_1_340px] flex-col gap-4 lg:max-w-[400px]">
        <div className="rounded-[28px] bg-white p-6">
          <div className="flex items-center justify-between gap-2">
            <h2 className="font-bold">What a bystander sees</h2>
            <span className="rounded-full bg-sky-pastel px-2.5 py-1 text-xs font-bold text-sky">On tag · public</span>
          </div>
          <TagMeter used={preview.bytesUsed} total={preview.bytesTotal} />
          {preview.problems.length > 0 && (
            <ul className="mt-3 flex flex-col gap-1 rounded-xl bg-peach-pastel p-3 text-sm text-peach">
              {preview.problems.map((p) => (
                <li key={p}>{friendlyProblem(p)}</li>
              ))}
            </ul>
          )}
        </div>
        <div className="rounded-[28px] bg-white/60 p-4">
          {draft.name.trim() ? (
            <EmergencyCard payload={preview.payload} trust="verified" offline />
          ) : (
            <p className="p-6 text-center text-sm text-ink-muted">Add your name to see the preview.</p>
          )}
        </div>
      </aside>
    </div>
  );
}

const inputCls =
  "h-12 w-full rounded-xl border border-line bg-surface px-4 outline-none focus:shadow-[0_0_0_3px_rgba(91,75,183,.35)]";

function friendlyProblem(p: string): string {
  const m = p.match(/^ec\[(\d)\]\.p/);
  if (m) return `Contact ${Number(m[1]) + 1}: enter a 10-digit mobile number.`;
  if (p.startsWith("ec[")) return "Each contact needs a name.";
  return p.replace(/^(\w+)(\[\d\])?: /, "");
}

function Card({ title, hint, onTag, setOnTag, children }: { title: string; hint?: string; onTag?: boolean; setOnTag?: (v: boolean) => void; children: React.ReactNode }) {
  return (
    <div className="flex flex-col gap-4 rounded-[28px] bg-white p-6">
      <div className="flex items-start justify-between gap-3">
        <div>
          <h2 className="font-bold">{title}</h2>
          {hint && <p className="mt-0.5 text-[13px] text-ink-muted">{hint}</p>}
        </div>
        {setOnTag && <OnTagSwitch value={onTag ?? false} onChange={setOnTag} />}
      </div>
      {children}
    </div>
  );
}

function Field({ label, htmlFor, onTag, setOnTag, children }: { label: string; htmlFor?: string; onTag?: boolean; setOnTag?: (v: boolean) => void; children: React.ReactNode }) {
  return (
    <div className="flex flex-col gap-1.5">
      <div className="flex items-center justify-between gap-2">
        <label htmlFor={htmlFor} className="text-sm font-semibold">{label}</label>
        {setOnTag && <OnTagSwitch value={onTag ?? false} onChange={setOnTag} small />}
      </div>
      {children}
    </div>
  );
}

function OnTagSwitch({ value, onChange, small }: { value: boolean; onChange: (v: boolean) => void; small?: boolean }) {
  return (
    <button
      type="button"
      role="switch"
      aria-checked={value}
      onClick={() => onChange(!value)}
      className={`flex shrink-0 items-center gap-2 rounded-full font-semibold transition-colors ${small ? "h-8 px-2.5 text-xs" : "h-9 px-3 text-[13px]"} ${
        value ? "bg-sky-pastel text-sky" : "bg-line/70 text-ink-muted"
      }`}
    >
      <span className={`relative h-4 w-7 rounded-full transition-colors ${value ? "bg-sky" : "bg-ink-muted/40"}`}>
        <span className={`absolute top-0.5 size-3 rounded-full bg-white transition-[left] ${value ? "left-3.5" : "left-0.5"}`} />
      </span>
      {value ? "On tag" : "Cloud only"}
    </button>
  );
}

function Choices<T extends string>({ options, value, onChange, tone = "mint" }: { options: readonly { value: T; label: string }[]; value?: T; onChange: (v: T | undefined) => void; tone?: "mint" | "rose" }) {
  const on = tone === "rose" ? "bg-rose text-white glow-rose" : "bg-navy text-white";
  return (
    <div className="flex flex-wrap gap-2" role="radiogroup">
      {options.map((o) => (
        <button
          key={o.value}
          type="button"
          role="radio"
          aria-checked={value === o.value}
          onClick={() => onChange(value === o.value ? undefined : o.value)}
          className={`mt-press h-11 min-w-12 rounded-full px-4 font-semibold transition-colors ${value === o.value ? on : "border border-line bg-surface hover:bg-bg"}`}
        >
          {o.label}
        </button>
      ))}
    </div>
  );
}

function ListInput({ items, onChange, max, maxLength, placeholder, tone }: { items: string[]; onChange: (v: string[]) => void; max: number; maxLength: number; placeholder: string; tone: "rose" | "lavender" }) {
  const [text, setText] = useState("");
  const chip = tone === "rose" ? "bg-rose-pastel text-rose" : "bg-lavender-pastel text-lavender";
  const add = () => {
    const value = text.trim();
    if (!value || items.length >= max || items.some((i) => i.toLowerCase() === value.toLowerCase())) return;
    onChange([...items, value]);
    setText("");
  };
  return (
    <div className="flex flex-col gap-3">
      {items.length > 0 && (
        <ul className="flex flex-wrap gap-2">
          {items.map((item) => (
            <li key={item} className={`mt-pop flex items-center gap-1 rounded-full py-1.5 pr-1.5 pl-3.5 text-sm font-semibold ${chip}`}>
              {item}
              <button type="button" aria-label={`Remove ${item}`} onClick={() => onChange(items.filter((i) => i !== item))} className="flex size-7 items-center justify-center rounded-full hover:bg-white/60">
                ×
              </button>
            </li>
          ))}
        </ul>
      )}
      {items.length < max ? (
        <div className="flex gap-2">
          <input
            value={text}
            maxLength={maxLength}
            onChange={(e) => setText(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === "Enter") {
                e.preventDefault();
                add();
              }
            }}
            placeholder={placeholder}
            aria-label={placeholder}
            className={inputCls}
          />
          <button type="button" onClick={add} className="h-12 shrink-0 rounded-xl border border-line bg-surface px-4 font-semibold">
            Add
          </button>
        </div>
      ) : (
        <p className="text-[13px] text-ink-muted">Maximum {max} reached.</p>
      )}
    </div>
  );
}

function Contacts({ contacts, onChange }: { contacts: Contact[]; onChange: (v: Contact[]) => void }) {
  const set = (i: number, patch: Partial<Contact>) => onChange(contacts.map((c, j) => (j === i ? { ...c, ...patch } : c)));
  return (
    <div className="flex flex-col gap-3">
      {contacts.map((c, i) => {
        const digits = c.phone.replace(/^\+91/, "");
        return (
          <div key={i} className="mt-pop grid grid-cols-1 gap-2 rounded-2xl border border-line p-3 sm:grid-cols-[1fr_120px]">
            <input aria-label={`Contact ${i + 1} name`} placeholder="Name" maxLength={40} value={c.name} onChange={(e) => set(i, { name: e.target.value })} className={inputCls} />
            <input aria-label={`Contact ${i + 1} relation`} placeholder="Relation" maxLength={20} value={c.relation ?? ""} onChange={(e) => set(i, { relation: e.target.value || undefined })} className={inputCls} />
            <div className="flex h-12 items-center rounded-xl border border-line bg-surface focus-within:shadow-[0_0_0_3px_rgba(91,75,183,.35)] sm:col-span-2">
              <span className="border-r border-line px-3 font-semibold text-ink-muted">+91</span>
              <input
                aria-label={`Contact ${i + 1} mobile number`}
                inputMode="numeric"
                maxLength={10}
                placeholder="10-digit mobile"
                value={digits}
                onChange={(e) => set(i, { phone: `+91${e.target.value.replace(/\D/g, "")}` })}
                className="h-full flex-1 bg-transparent px-3 outline-none"
              />
              <button type="button" onClick={() => onChange(contacts.filter((_, j) => j !== i))} className="h-full px-4 text-sm font-semibold text-rose">
                Remove
              </button>
            </div>
          </div>
        );
      })}
      {contacts.length < 3 && (
        <button type="button" onClick={() => onChange([...contacts, { name: "", phone: "+91" }])} className="flex h-12 items-center justify-center gap-2 rounded-xl border border-dashed border-line font-semibold text-mint">
          <Icon name="phone" size={18} /> Add contact
        </button>
      )}
    </div>
  );
}

function TagMeter({ used, total }: { used: number; total: number }) {
  const pct = Math.min(100, Math.round((used / total) * 100));
  const tone = used > total ? "bg-rose" : pct > 85 ? "bg-peach" : "bg-mint";
  return (
    <div className="mt-4">
      <div className="h-2.5 overflow-hidden rounded-full bg-line" role="meter" aria-valuenow={used} aria-valuemin={0} aria-valuemax={total} aria-label="Tag memory used">
        <div className={`h-full rounded-full transition-[width] duration-300 ${tone}`} style={{ width: `${pct}%` }} />
      </div>
      <p className="mt-2 text-[13px] text-ink-muted">
        Uses <b className="text-ink">{used}</b> of {total} bytes on the tag
      </p>
    </div>
  );
}
