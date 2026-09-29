import { Check, ChevronDown, RefreshCw } from "lucide-react";
import { switchRole } from "@/app/role-actions";
import { rolePresentation, type RoleSlug } from "@/lib/roles";

export function RoleSwitcher({ activeRole, assignedRoles }: { activeRole: RoleSlug; assignedRoles: RoleSlug[] }) {
  if (assignedRoles.length < 2) return null;
  return <details className="role-switcher">
    <summary aria-label={`Switch role. Currently viewing as ${rolePresentation[activeRole].label}`}>
      <RefreshCw size={16}/><span><small>Viewing as</small><strong>{rolePresentation[activeRole].label}</strong></span><ChevronDown size={16}/>
    </summary>
    <div className="role-switcher__menu">
      <p>Switch workspace view</p>
      {assignedRoles.map((role) => <form action={switchRole} key={role}>
        <input type="hidden" name="role" value={role}/>
        <button type="submit" aria-current={role === activeRole ? "true" : undefined}>
          <span>{rolePresentation[role].label}</span>{role === activeRole && <Check size={16}/>} 
        </button>
      </form>)}
      <small>This changes the workspace view, not your assigned permissions.</small>
    </div>
  </details>;
}
