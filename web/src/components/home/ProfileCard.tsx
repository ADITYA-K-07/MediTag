import { Icon } from "@/components/Icon";

/**
 * The hero's illustration: an emergency profile as a bystander sees it after tapping a tag.
 * Drawn in HTML from the real card's parts (no photos). Sample person only.
 */
export function ProfileCard() {
  return (
    <div className="relative mx-auto w-full max-w-[380px] py-6 sm:max-w-[460px] sm:py-10">
      {/* Soft disc behind the card */}
      <div aria-hidden="true" className="absolute top-1/2 left-1/2 aspect-square w-[108%] sm:w-[118%] -translate-x-1/2 -translate-y-1/2 rounded-full bg-periwinkle" />
      <div aria-hidden="true" className="absolute top-[4%] right-[-4%] size-24 rounded-full border-2 border-white/70" />

      <figure
        aria-label="Example emergency profile shown after scanning a MediTag"
        className="hero-card relative rotate-[2deg] sm:rotate-[3deg] rounded-[32px] bg-white p-6 shadow-[0_30px_70px_-20px_rgba(23,26,46,.28)] transition-transform duration-500 hover:rotate-0 sm:p-7"
      >
        <div className="flex items-center justify-between">
          <span className="flex items-center gap-1.5 rounded-full bg-mint-pastel px-3.5 py-2 text-[13px] font-bold text-mint">
            <Icon name="check" size={15} strokeWidth={3} /> Verified profile
          </span>
          <span className="text-[13px] text-ink-muted">MT • 4829</span>
        </div>

        <div className="mt-6 flex items-center gap-4">
          <span className="flex size-14 shrink-0 items-center justify-center rounded-2xl bg-periwinkle-pastel text-lg font-bold text-[#3B4FA8]">RS</span>
          <div>
            <p className="text-[12px] font-bold tracking-wide text-ink-muted uppercase">Emergency profile</p>
            <p className="font-heading text-[22px] font-bold tracking-tight">Rahul Sharma</p>
          </div>
        </div>

        <div className="mt-5 grid grid-cols-[0.95fr_1.25fr] gap-3">
          <div className="flex flex-col justify-between rounded-3xl bg-navy p-4 text-white">
            <span className="text-[13px] font-semibold opacity-80">Blood type</span>
            <span className="mt-3 font-heading text-[44px] leading-none font-extrabold tracking-tight">B+</span>
          </div>
          <div className="rounded-3xl bg-periwinkle-pastel p-4">
            <span className="text-[13px] font-semibold text-ink-muted">Emergency contact</span>
            <p className="mt-3 text-[15px] font-bold">Priya · Mother</p>
            <p className="text-[14px] font-semibold">+91 98••• ••210</p>
          </div>
        </div>

        <p className="mt-5 text-[12px] font-bold tracking-wide text-ink-muted uppercase">Critical alerts</p>
        <div className="mt-2 flex flex-wrap gap-2">
          <span className="rounded-xl bg-rose-pastel px-3 py-2 text-[13px] font-bold text-rose">Severe penicillin allergy</span>
          <span className="rounded-xl bg-[#FFF1CC] px-3 py-2 text-[13px] font-bold text-[#7A5600]">Type 1 diabetes</span>
        </div>

        <div className="mt-5 flex items-center gap-3 rounded-2xl bg-bg px-4 py-3 text-[13px] text-ink-muted">
          <Icon name="lock" size={16} />
          <span className="flex-1">Full record stays private</span>
          <Icon name="arrow" size={18} className="text-ink" />
        </div>
      </figure>

      {/* Floating chip */}
      <div className="hero-chip absolute bottom-0 left-0 flex -rotate-[4deg] items-center gap-3 rounded-2xl bg-navy px-4 py-3.5 text-white shadow-[0_18px_40px_-14px_rgba(23,26,46,.55)] sm:bottom-4 sm:left-[-10%]">
        <span className="flex size-9 items-center justify-center rounded-xl bg-white/10">
          <Icon name="scan" size={20} />
        </span>
        <span>
          <span className="block text-[14px] font-bold">Tap or scan</span>
          <span className="block text-[12.5px] opacity-80">Works with the tag or printed QR</span>
        </span>
      </div>
    </div>
  );
}
