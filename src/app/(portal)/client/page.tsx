import { CalendarDays, ChevronRight, CircleCheck, HeartHandshake, MapPin } from "lucide-react";
import { AppShell } from "@/components/app-shell";
import { createClient } from "@/lib/supabase/server";

export default async function ClientHome() {
  const supabase = await createClient();
  const { data } = supabase ? await supabase.auth.getClaims() : { data: null };
  const name = String(data?.claims?.user_metadata?.display_name ?? data?.claims?.email ?? "Client");

  return (
    <AppShell name={name}>
      <div className="portal-page">
        <div className="portal-heading"><div><p className="welcome-line">Client overview</p><h1>Hello, {name.split("@")[0]}</h1><p>Your secure Tebelopele services will appear here as each approved phase goes live.</p></div><span className="status-label"><CircleCheck size={16}/> Account connected</span></div>
        <section className="next-action" id="appointments"><div><CalendarDays size={28}/><div><h2>Your next appointment</h2><p>No appointment is scheduled. Appointment booking arrives in Phase 3.</p></div></div><button className="button button--quiet" disabled>Book later</button></section>
        <div className="portal-columns">
          <section><h2>Quick access</h2><div className="action-list"><button disabled><MapPin/><span><strong>Find a facility</strong><small>Service directory arrives in Phase 2</small></span><ChevronRight/></button><button disabled><HeartHandshake/><span><strong>Talk to a person</strong><small>Human support arrives in Phase 6</small></span><ChevronRight/></button></div></section>
          <section className="foundation-note"><h2>What is available now</h2><p>Your authenticated account foundation and protected portal are active. No clinical or appointment data is shown until those workflows are implemented and approved.</p></section>
        </div>
      </div>
    </AppShell>
  );
}
