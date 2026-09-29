import Link from "next/link";
import { Menu, MessageCircle, X } from "lucide-react";
import { BrandLogo } from "@/components/brand-logo";

export function SiteHeader() {
  return (
    <header className="site-header">
      <div className="site-header__inner">
        <Link href="/" aria-label="Tebelopele home"><BrandLogo compact /></Link>
        <nav className="desktop-nav" aria-label="Primary navigation">
          <Link href="/services">Services</Link>
          <Link href="/locations">Locations</Link>
          <Link href="/health">Health information</Link>
          <Link href="/faqs">FAQs</Link>
          <Link href="/demo">Platform demo</Link>
        </nav>
        <div className="header-actions">
          <Link className="button button--quiet" href="/sign-in">Sign in</Link>
          <Link className="button button--primary" href="/sign-in">
            <MessageCircle size={18} aria-hidden="true" /> Talk to us
          </Link>
        </div>
        <details className="mobile-menu">
          <summary aria-label="Open menu"><Menu className="menu-open"/><X className="menu-close"/></summary>
          <nav aria-label="Mobile navigation">
            <Link href="/services">Services</Link>
            <Link href="/locations">Locations</Link>
            <Link href="/health">Health information</Link>
            <Link href="/faqs">FAQs</Link>
            <Link href="/demo">Platform demo</Link>
            <Link href="/sign-in">Sign in</Link>
          </nav>
        </details>
      </div>
    </header>
  );
}
