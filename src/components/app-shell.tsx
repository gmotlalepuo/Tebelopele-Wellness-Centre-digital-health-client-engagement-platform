import Link from "next/link";
import type { ReactNode } from "react";
import { BellRing, Bot, CalendarDays, Home, LifeBuoy, Settings2, ShieldCheck, UserRound } from "lucide-react";
import { BrandLogo } from "@/components/brand-logo";
import { signOut } from "@/app/auth/actions";
import { RoleSwitcher } from "@/components/role-switcher";
import type { RoleSlug } from "@/lib/roles";

const links = [
  { label: "Overview", href: "/client", icon: Home },
  { label: "Appointments", href: "/client/appointments", icon: CalendarDays },
  { label: "Notifications", href: "/client/notifications", icon: BellRing },
  { label: "Ask Tebelopele", href: "/client/chat", icon: Bot },
  { label: "My profile", href: "/client/profile", icon: UserRound },
  { label: "Preferences", href: "/client/preferences", icon: Settings2 },
  { label: "Consent", href: "/client/consent", icon: ShieldCheck },
  { label: "Get support", href: "/client/support", icon: LifeBuoy },
];

export function AppShell({ children, name, activeRole, assignedRoles }: { children: ReactNode; name: string; activeRole: RoleSlug; assignedRoles: RoleSlug[] }) {
  return (
    <div className="app-frame">
      <a className="skip-link" href="#client-main">Skip to main content</a>
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
          <div className="app-topbar__account"><RoleSwitcher activeRole={activeRole} assignedRoles={assignedRoles}/><span className="user-chip"><span aria-hidden="true">{name.slice(0, 1).toUpperCase()}</span>{name}</span></div>
        </header>
        <main id="client-main" tabIndex={-1}>{children}</main>
      </div>
    </div>
  );
}
