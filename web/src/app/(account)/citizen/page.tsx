import type { Metadata } from "next";
import { AccountShell } from "@/components/account/AccountShell";
import { CitizenHome } from "./CitizenHome";

export const metadata: Metadata = { title: "Dashboard" };

export default function CitizenPage() {
  return (
    <AccountShell>
      <CitizenHome />
    </AccountShell>
  );
}
