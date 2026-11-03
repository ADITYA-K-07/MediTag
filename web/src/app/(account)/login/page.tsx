import type { Metadata } from "next";
import { ProfileCard } from "@/components/home/ProfileCard";
import { LoginFlow } from "./LoginFlow";

export const metadata: Metadata = { title: "Log in" };

export default function LoginPage() {
  return (
    <main className="mx-auto grid w-full max-w-[1200px] flex-1 items-center gap-10 overflow-x-clip px-5 py-8 sm:px-10 lg:grid-cols-[1fr_1fr] lg:gap-16">
      <div className="mx-auto w-full max-w-[440px] lg:mx-0">
        <LoginFlow />
      </div>
      {/* What your tag will show: same card as the home page. Hidden on phones to keep the form first. */}
      <div className="hidden lg:block">
        <ProfileCard />
      </div>
    </main>
  );
}
