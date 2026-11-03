import type { Metadata } from "next";
import { AccountShell } from "@/components/account/AccountShell";
import { ProfileEditor } from "./ProfileEditor";

export const metadata: Metadata = { title: "Emergency profile" };

export default function ProfilePage() {
  return (
    <AccountShell>
      <ProfileEditor />
    </AccountShell>
  );
}
