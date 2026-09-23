import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "MediTag — Emergency medical information in one tap",
  description: "Secure NFC and web access to critical emergency medical information.",
  icons: { icon: "/favicon.svg", shortcut: "/favicon.svg" },
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return <html lang="en"><body>{children}</body></html>;
}
