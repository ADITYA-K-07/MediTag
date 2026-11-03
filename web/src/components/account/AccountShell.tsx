"use client";

import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { useEffect } from "react";
import { signOut, useSession } from "@/components/auth/AuthProvider";
import { Logo } from "@/components/Icon";

const NAV = [
  { href: "/citizen", label: "Dashboard" },
  { href: "/citizen/profile", label: "Emergency profile" },
];

/** Signed-in page frame. Sends visitors who aren't logged in to /login. */
export function AccountShell({ children }: { children: React.ReactNode }) {
  const { user, loading } = useSession();
  const router = useRouter();
  const path = usePathname();

  useEffect(() => {
    if (!loading && !user) router.replace("/login");
  }, [loading, user, router]);

  if (loading || !user) {
    return (
      <div className="flex flex-1 items-center justify-center" aria-label="Loading">
        <span className="size-10 animate-spin rounded-full border-4 border-mint-pastel border-t-mint" />
      </div>
    );
  }

  return (
    <div className="mx-auto flex w-full max-w-[1100px] flex-1 flex-col px-5 sm:px-8">
      <header className="flex flex-wrap items-center justify-between gap-3 py-5">
        <Link href="/citizen" aria-label="MediTag dashboard">
          <Logo />
        </Link>
        <nav aria-label="Account" className="order-3 flex w-full gap-1 overflow-x-auto sm:order-none sm:w-auto">
          {NAV.map((n) => (
            <Link
              key={n.href}
              href={n.href}
              aria-current={path === n.href ? "page" : undefined}
              className={`flex h-10 items-center rounded-full px-4 text-sm font-semibold whitespace-nowrap ${
                path === n.href ? "bg-navy text-white" : "text-[#3D4258] hover:bg-white/70 hover:text-navy"
              }`}
            >
              {n.label}
            </Link>
          ))}
        </nav>
        <button
          onClick={() => signOut().then(() => router.replace("/"))}
          className="mt-press h-10 rounded-full bg-white px-5 text-sm font-semibold text-navy hover:bg-white/80"
        >
          Log out
        </button>
      </header>
      <main className="flex-1 pb-12">{children}</main>
    </div>
  );
}
