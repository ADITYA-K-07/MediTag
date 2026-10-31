import type { Metadata } from "next";
import { ScanFlow } from "./ScanFlow";

export const metadata: Metadata = { title: "Scan a MediTag" };

export default function ScanPage() {
  return (
    <main className="mx-auto flex w-full max-w-[440px] flex-1 flex-col px-5 py-4">
      <ScanFlow />
    </main>
  );
}
