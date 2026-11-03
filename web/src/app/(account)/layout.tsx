import { AuthProvider } from "@/components/auth/AuthProvider";

// Signed-in area (login, citizen dashboard). Kept out of the root layout so the public scan and
// emergency pages load without the Firebase SDK.
export default function AccountLayout({ children }: { children: React.ReactNode }) {
  return (
    <AuthProvider>
      <div className="flex flex-1 flex-col bg-periwinkle-pastel/60">{children}</div>
    </AuthProvider>
  );
}
