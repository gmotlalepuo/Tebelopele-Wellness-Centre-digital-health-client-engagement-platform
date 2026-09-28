import type { ReactNode } from "react";
import Link from "next/link";
import { Search } from "lucide-react";
import { SiteHeader } from "@/components/site-header";

export function PublicShell({ children }: { children: ReactNode }) {
  return (
    <>
      <a className="skip-link" href="#main-content">Skip to main content</a>
      <SiteHeader />
      <div id="main-content" tabIndex={-1}>{children}</div>
      <footer className="public-footer">
        <div><strong>Tebelopele Wellness Centre</strong><p>A secure digital route to information, services and support.</p></div>
        <nav aria-label="Footer navigation"><Link href="/services">Services</Link><Link href="/locations">Locations</Link><Link href="/health">Health information</Link><Link href="/faqs">FAQs</Link><Link href="/privacy">Privacy</Link></nav>
        <form action="/search" role="search"><label htmlFor="footer-search">Search this site</label><div><input id="footer-search" name="q" type="search"/><button aria-label="Search"><Search size={18}/></button></div></form>
      </footer>
    </>
  );
}

export function PageIntro({ title, children, action }: { title: string; children: ReactNode; action?: ReactNode }) {
  return <header className="page-intro"><div><Link href="/" className="back-link">Tebelopele home</Link><h1>{title}</h1><div className="page-intro__copy">{children}</div></div>{action}</header>;
}

export function PreviewNotice() {
  return <div className="preview-notice" role="note"><strong>Implementation preview</strong><span>This sample content shows the completed interface and must be replaced with approved Tebelopele information before launch.</span></div>;
}

export function EmptyState({ title, children }: { title: string; children: ReactNode }) {
  return <div className="empty-state"><h2>{title}</h2><p>{children}</p></div>;
}
