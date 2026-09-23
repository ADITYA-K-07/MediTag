import Link from "next/link";
import { ArrowLeft, ArrowRight, HeartPulse } from "lucide-react";
import { Button } from "@/components/ui/button";

export function MediTagHeader({ backHref, backLabel }: { backHref?: string; backLabel?: string }) {
  return (
    <header className="site-header">
      <Link className="brand" href="/" aria-label="MediTag home">
        <span className="brand-mark"><HeartPulse aria-hidden="true" /></span><span>MediTag</span>
      </Link>
      {backHref ? (
        <Link className="back-link" href={backHref}><ArrowLeft aria-hidden="true" /> {backLabel ?? "Back"}</Link>
      ) : (
        <nav className="main-nav" aria-label="Main navigation">
          <a href="#how-it-works">How it works</a><a href="#privacy">Privacy</a><Link href="/doctor">For doctors</Link>
        </nav>
      )}
      <Button asChild className="header-action"><Link href="/citizen">My profile <ArrowRight aria-hidden="true" /></Link></Button>
    </header>
  );
}
