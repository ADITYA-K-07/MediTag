import Link from "next/link";
import { ProfileCard } from "@/components/home/ProfileCard";
import { Icon, Logo } from "@/components/Icon";

const steps = [
  {
    title: "Add your info",
    body: "Blood group, allergies, medicines and who to call. Upload past reports for doctors.",
    tone: "bg-mint-pastel text-mint",
  },
  {
    title: "Program up to 3 tags",
    body: "Wallet card, car sticker, bracelet. Each tag is signed and locked, so no one else can change it.",
    tone: "bg-periwinkle-pastel text-[#3B4FA8]",
  },
  {
    title: "Anyone can tap it",
    body: "A bystander sees what helps and calls your family. Verified doctors see the full history.",
    tone: "bg-rose-pastel text-rose",
  },
];

const onTag = ["Name and age", "Blood group", "Allergies and critical conditions", "Current medicines", "Emergency contacts"];
const inCloud = ["Past surgeries and diagnoses", "Lab reports and scans", "Prescriptions", "Doctor notes"];

export default function Home() {
  return (
    <div className="flex flex-1 flex-col overflow-x-clip bg-periwinkle-pastel/60">
      <div className="mx-auto w-full max-w-[1200px] px-5 sm:px-10">
        <header className="flex items-center justify-between gap-4 py-5">
          <Link href="/" aria-label="MediTag home">
            <Logo />
          </Link>
          <nav aria-label="Main" className="hidden items-center gap-8 text-[15px] font-semibold text-[#3D4258] md:flex">
            <a href="#how" className="hover:text-navy">How it works</a>
            <a href="#privacy" className="hover:text-navy">Privacy</a>
            <a href="#doctors" className="hover:text-navy">For doctors</a>
          </nav>
          <Link href="/login" className="mt-press flex h-12 items-center rounded-full bg-navy px-6 text-[15px] font-bold text-white hover:bg-[#262A45]">
            Log in
          </Link>
        </header>

        {/* Hero */}
        <section className="grid items-center gap-10 pt-10 pb-20 lg:grid-cols-[1.2fr_1fr] lg:gap-4 lg:pt-16 lg:pb-28">
          <div className="mt-stagger min-w-0">
            <p className="flex items-center gap-2.5 text-[13px] font-bold tracking-[0.08em] text-[#3D4258] uppercase">
              <span className="size-2.5 rounded-full bg-mint shadow-[0_0_0_4px_rgba(31,122,92,.15)]" />
              Emergency information, when it matters
            </p>
            <h1 className="mt-5 font-heading text-[clamp(42px,5.5vw,78px)] leading-[0.94] font-extrabold tracking-[-0.055em] text-navy">
              One tap can tell them how to help.
            </h1>
            <p className="mt-6 max-w-[520px] text-[18px] leading-relaxed text-[#3D4258]">
              MediTag keeps your critical medical information on a secure NFC tag. Anyone can read it in seconds, even with no
              internet, and call your family.
            </p>
            <div className="mt-9 flex flex-wrap gap-3">
              <Link href="/scan" className="mt-press flex h-14 items-center gap-2.5 rounded-full bg-navy px-7 text-[16px] font-bold text-white hover:bg-[#262A45]">
                <Icon name="nfc" size={20} /> Scan a MediTag
              </Link>
              <a href="#how" className="mt-press flex h-14 items-center rounded-full bg-white px-7 text-[16px] font-semibold text-navy hover:bg-white/80">
                See how it works
              </a>
            </div>
            <p className="mt-7 flex items-center gap-2.5 text-[14.5px] text-[#3D4258]">
              <Icon name="shield" size={18} className="text-mint" /> Critical details are signed and checked for tampering.
            </p>
          </div>
          <ProfileCard />
        </section>
      </div>

      {/* How it works */}
      <section id="how" className="bg-white py-20 sm:py-28">
        <div className="mx-auto max-w-[1200px] px-5 sm:px-10">
          <h2 className="max-w-[640px] font-heading text-[clamp(32px,4vw,52px)] leading-[1.02] font-extrabold tracking-[-0.04em] text-navy">
            Set it up once. It speaks for you every day.
          </h2>
          <ol className="mt-stagger mt-12 grid gap-5 md:grid-cols-3">
            {steps.map((s, i) => (
              <li key={s.title} className="flex flex-col gap-4 rounded-[28px] bg-bg p-7 transition-transform duration-300 hover:-translate-y-1">
                <span className={`flex size-12 items-center justify-center rounded-2xl font-heading text-xl font-extrabold ${s.tone}`}>{i + 1}</span>
                <h3 className="text-[20px] font-bold text-navy">{s.title}</h3>
                <p className="leading-relaxed text-[#3D4258]">{s.body}</p>
              </li>
            ))}
          </ol>
        </div>
      </section>

      {/* Two layers */}
      <section id="privacy" className="bg-navy py-20 text-white sm:py-28">
        <div className="mx-auto grid max-w-[1200px] gap-12 px-5 sm:px-10 lg:grid-cols-[1fr_1.2fr] lg:items-center">
          <div>
            <h2 className="font-heading text-[clamp(32px,4vw,52px)] leading-[1.02] font-extrabold tracking-[-0.04em]">
              Public when it saves you. Private everywhere else.
            </h2>
            <p className="mt-5 max-w-[460px] text-[17px] leading-relaxed text-white/80">
              You choose what goes on the tag. Your full history stays in the cloud, and only a verified doctor who taps your tag can open
              it, for 24 hours. You see every view.
            </p>
          </div>
          <div className="grid gap-4 sm:grid-cols-2">
            <div className="rounded-[28px] bg-white p-6 text-navy">
              <span className="rounded-full bg-mint-pastel px-3 py-1.5 text-[13px] font-bold text-mint">On the tag · works offline</span>
              <ul className="mt-5 flex flex-col gap-3">
                {onTag.map((t) => (
                  <li key={t} className="flex items-center gap-2.5 font-semibold">
                    <Icon name="check" size={17} strokeWidth={3} className="shrink-0 text-mint" /> {t}
                  </li>
                ))}
              </ul>
            </div>
            <div className="rounded-[28px] bg-[#262A45] p-6">
              <span className="rounded-full bg-white/10 px-3 py-1.5 text-[13px] font-bold">In the cloud · doctors only</span>
              <ul className="mt-5 flex flex-col gap-3">
                {inCloud.map((t) => (
                  <li key={t} className="flex items-center gap-2.5 font-semibold text-white/90">
                    <Icon name="lock" size={16} className="shrink-0 text-periwinkle" /> {t}
                  </li>
                ))}
              </ul>
            </div>
          </div>
        </div>
      </section>

      {/* Roles */}
      <section id="doctors" className="py-20 sm:py-28">
        <div className="mx-auto grid max-w-[1200px] gap-5 px-5 sm:px-10 md:grid-cols-2">
          <div className="flex flex-col gap-4 rounded-[32px] bg-white p-8 sm:p-10">
            <h2 className="font-heading text-[30px] leading-tight font-extrabold tracking-[-0.03em] text-navy">For you and your family</h2>
            <p className="leading-relaxed text-[#3D4258]">
              Fill in your profile on the web or in the app, see who scanned your tag, and revoke a lost tag from any device.
            </p>
            <Link href="/login" className="mt-press mt-auto flex h-12 w-fit items-center gap-2 rounded-full bg-navy px-6 font-bold text-white hover:bg-[#262A45]">
              Create your profile <Icon name="arrow" size={18} />
            </Link>
          </div>
          <div className="flex flex-col gap-4 rounded-[32px] bg-navy p-8 text-white sm:p-10">
            <h2 className="font-heading text-[30px] leading-tight font-extrabold tracking-[-0.03em]">For doctors</h2>
            <p className="leading-relaxed text-white/80">
              Get verified with your Medical Council registration. Tap a patient&apos;s tag to see surgeries, reports and prescriptions
              before you treat.
            </p>
            <Link href="/login" className="mt-press mt-auto flex h-12 w-fit items-center gap-2 rounded-full bg-white px-6 font-bold text-navy hover:bg-white/85">
              Doctor sign-up <Icon name="arrow" size={18} />
            </Link>
          </div>
        </div>
      </section>

      <footer className="mx-auto w-full max-w-[1200px] px-5 pb-10 sm:px-10">
        <p aria-hidden="true" className="font-heading text-[clamp(64px,15vw,220px)] leading-[0.85] font-extrabold tracking-[-0.06em] text-navy/[0.07] select-none">
          MediTag
        </p>
        <div className="mt-6 flex flex-wrap justify-between gap-3 text-[14px] text-[#3D4258]">
          <span>© 2026 MediTag · Engineering course project</span>
          <span>Saw an accident? <Link href="/scan" className="font-semibold text-navy underline-offset-4 hover:underline">Scan a tag</Link></span>
        </div>
      </footer>
    </div>
  );
}
