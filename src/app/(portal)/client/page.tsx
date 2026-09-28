import { CalendarDays, ChevronRight, CircleCheck, HeartHandshake, MapPin, UserRound } from "lucide-react";
import Link from "next/link";
import { getClientContext } from "@/lib/client-data";

export default async function ClientHome() {
  const client = await getClientContext();
  const name = client.preferredName || client.displayName;

  return (
      <div className="portal-page">
        <div className="portal-heading"><div><p className="welcome-line">Client overview</p><h1>Hello, {name.split("@")[0]}</h1><p>Manage your profile, communication choices and consent from one secure place.</p></div>{client.configured ? <span className="status-label"><CircleCheck size={16}/> Account connected</span> : <span className="status-label status-label--preview">Preview mode</span>}</div>
        {!client.configured && <div className="preview-notice"><strong>Local preview</strong><span>Connect Supabase to save client information and enforce authenticated access.</span></div>}
        <section className="next-action" id="appointments"><div><CalendarDays size={28}/><div><h2>Your appointments</h2><p>Choose an available service and time, or review an existing booking.</p></div></div><Link className="button button--primary" href="/client/appointments">Open schedule</Link></section>
        <div className="portal-columns">
          <section><h2>Quick access</h2><div className="action-list"><Link href="/locations"><MapPin/><span><strong>Find a facility</strong><small>View published locations and services</small></span><ChevronRight/></Link><Link href="/client/profile"><UserRound/><span><strong>Review your profile</strong><small>Keep your permitted details current</small></span><ChevronRight/></Link><button disabled id="support"><HeartHandshake/><span><strong>Talk to a person</strong><small>Human support arrives in Phase 6</small></span><ChevronRight/></button></div></section>
          <section className="foundation-note"><h2>Your choices matter</h2><p>Communication permissions and consent are recorded separately so you can review or change them without altering unrelated profile information.</p><Link className="text-link" href="/client/preferences">Review communication choices</Link></section>
        </div>
      </div>
  );
}
