import type { Metadata } from "next";
import Link from "next/link";
import { Suspense } from "react";
import { EmergencyCard } from "@/components/EmergencyCard";
import { Icon } from "@/components/Icon";
import { getPublicEmergency } from "@/lib/api";

// Opened from the tag's URL record (iPhone, phones without the app) or the QR wallet card.
export const metadata: Metadata = { title: "Emergency info", robots: { index: false, follow: false } };

// The shell (top bar, 108 button) is prerendered so it appears instantly; only the person's details stream in.
export default function EmergencyPage(props: PageProps<"/e/[tagId]">) {
  return (
    <main className="mx-auto w-full max-w-[440px] flex-1 px-5 pt-4 pb-10">
      <div className="flex h-16 items-center gap-2.5">
        <Link href="/" aria-label="MediTag home" className="flex size-11 items-center justify-center rounded-full border border-line bg-surface">
          <Icon name="back" />
        </Link>
        <span className="font-heading text-[17px] font-bold">Emergency info</span>
      </div>
      <Suspense fallback={<CardSkeleton />}>
        <EmergencyDetails params={props.params} />
      </Suspense>
    </main>
  );
}

async function EmergencyDetails({ params }: { params: Promise<{ tagId: string }> }) {
  const result = await getPublicEmergency((await params).tagId);
  if (result.status === "active") return <EmergencyCard payload={result.payload} trust="server" offline={false} />;

  const notice = {
    revoked: ["This tag has been deactivated", "Its owner reported it lost. Call 108 for an ambulance if someone needs help."],
    "not-found": ["Unknown MediTag", "This link doesn't match any MediTag. Check for another tag or a QR card."],
    unavailable: ["Can't load this tag right now", "Try scanning the tag itself with Android Chrome or the MediTag app. That works offline."],
  }[result.status];
  return (
    <>
      <div className="rounded-2xl bg-peach-pastel p-4 text-peach">
        <p className="font-bold">{notice[0]}</p>
        <p className="mt-1 text-sm">{notice[1]}</p>
      </div>
      <a href="tel:108" className="mt-press glow-rose mt-5 flex h-16 items-center justify-center gap-3 rounded-[18px] bg-rose text-[17px] font-bold text-white">
        <Icon name="phone" /> Call 108 Ambulance
      </a>
    </>
  );
}

function CardSkeleton() {
  return (
    <div className="flex animate-pulse flex-col gap-3.5" aria-label="Loading emergency info">
      <div className="h-16 rounded-2xl bg-line" />
      <div className="h-14 w-2/3 rounded-2xl bg-line" />
      <div className="h-24 rounded-[20px] bg-rose-pastel" />
      <div className="h-[68px] rounded-[18px] bg-rose-pastel" />
    </div>
  );
}
