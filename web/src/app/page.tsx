import Link from "next/link";
import { Icon, Logo } from "@/components/Icon";

const steps = [
  { n: "1", tone: "bg-mint-pastel text-mint", title: "Add your info", body: "Fill in your emergency profile and upload past reports, on the web or in the app." },
  { n: "2", tone: "bg-lavender-pastel text-lavender", title: "Program up to 3 tags", body: "Car, wallet, bracelet. Each tag is locked and signed, so no one else can change it." },
  { n: "3", tone: "bg-rose-pastel text-rose", title: "Anyone can scan", body: "In an emergency, a tap shows blood group and family contacts. Verified doctors see the full history." },
];

export default function Home() {
  return (
    <div className="mx-auto w-full max-w-[1180px] px-5 sm:px-10">
      <header className="flex flex-wrap items-center justify-between gap-4 py-5">
        <Logo />
        <nav aria-label="Main" className="flex gap-7 text-[14.5px] font-semibold text-ink-muted">
          <a href="#how" className="hover:text-ink">How it works</a>
        </nav>
      </header>

      <section className="flex flex-wrap items-center gap-14 pt-14 pb-22">
        <div className="mt-stagger min-w-0 flex-[1_1_460px]">
          <span className="inline-block rounded-full bg-mint-pastel px-3.5 py-1.5 text-[13px] font-semibold text-mint">Emergency medical ID for India</span>
          <h1 className="mt-5 font-heading text-[clamp(40px,5vw,60px)] leading-[1.05] font-extrabold tracking-[-0.03em]">
            Medical info that speaks when you can&apos;t.
          </h1>
          <p className="mt-5 max-w-[520px] text-lg leading-relaxed text-ink-muted">
            One tap on a MediTag shows a person&apos;s blood group, allergies and family contacts, even with no internet. Verified doctors can open the full medical history.
          </p>
          <div className="mt-8 flex flex-wrap gap-3.5">
            <Link href="/scan" className="mt-press glow-rose inline-flex h-15 items-center gap-3 rounded-full bg-rose pr-7 pl-5.5 text-[17px] font-bold text-white">
              <span className="relative flex size-6 items-center justify-center">
                <span className="mt-pulse absolute size-3 rounded-full bg-white/45" />
                <Icon name="nfc" size={22} className="relative" />
              </span>
              Scan a MediTag
            </Link>
            <a href="#how" className="inline-flex h-15 items-center rounded-full border border-line bg-surface px-6.5 font-semibold">How it works</a>
          </div>
          <div className="mt-5.5 flex flex-wrap gap-2 text-[12.5px] font-semibold">
            <span className="rounded-full bg-sky-pastel px-3 py-1.5 text-sky">Offline on Android Chrome</span>
            <span className="rounded-full bg-rose-pastel px-3 py-1.5 text-rose">No login to scan</span>
            <span className="rounded-full bg-lavender-pastel px-3 py-1.5 text-lavender">iPhone: just tap the tag</span>
          </div>
        </div>
      </section>

      <section id="how" className="pb-22">
        <h2 className="font-heading text-[34px] font-extrabold tracking-tight">How MediTag works</h2>
        <p className="mt-2.5 text-ink-muted">Your account, data and tags stay in sync across the app and the website.</p>
        <div className="mt-stagger mt-9 grid grid-cols-[repeat(auto-fit,minmax(250px,1fr))] gap-5">
          {steps.map((s) => (
            <div key={s.n} className="shadow-card flex flex-col gap-3.5 rounded-3xl border border-line bg-surface p-7 transition-transform hover:-translate-y-0.5">
              <span className={`flex size-11 items-center justify-center rounded-[14px] font-heading text-lg font-extrabold ${s.tone}`}>{s.n}</span>
              <h3 className="text-lg font-bold">{s.title}</h3>
              <p className="leading-relaxed text-ink-muted">{s.body}</p>
            </div>
          ))}
        </div>
      </section>

      <footer className="flex flex-wrap justify-between gap-4 border-t border-line pt-7 pb-9 text-[13.5px] text-ink-muted">
        <span>© 2026 MediTag · Engineering course project</span>
      </footer>
    </div>
  );
}
