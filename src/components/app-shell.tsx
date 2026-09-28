import Link from "next/link";
import type { ReactNode } from "react";
import { CalendarDays, Home, LifeBuoy, UserRound } from "lucide-react";
import { BrandLogo } from "@/components/brand-logo";
import { signOut } from "@/app/auth/actions";

const links = [
  { label: "Overview", href: "/client", icon: Home },
  { label: "Appointments", href: "/client#appointments", icon: CalendarDays },
  { label: "My profile", href: "/client#profile", icon: UserRound },
  { label: "Get support", href: "/client#support", icon: LifeBuoy },
];

export function AppShell({ children, name }: { children: ReactNode; name: string }) {
  return (
    <div className="app-frame">
      <aside className="app-sidebar">
        <Link href="/" aria-label="Tebelopele home"><BrandLogo compact /></Link>
        <nav aria-label="Client portal">
          {links.map(({ label, href, icon: Icon }) => (
            <Link href={href} key={label}><Icon size={19} aria-hidden="true" />{label}</Link>
          ))}
        </nav>
        <form action={signOut}><button className="button button--quiet" type="submit">Sign out</button></form>
      </aside>
      <div className="app-content">
        <header className="app-topbar">
          <span>Client portal</span>
          <span className="user-chip"><span aria-hidden="true">{name.slice(0, 1).toUpperCase()}</span>{name}</span>
        </header>
        <main>{children}</main>
      </div>
    </div>
  );
}
