import Link from "next/link";
import { BadgeCheck, BriefcaseMedical, LogOut, UsersRound } from "lucide-react";
import { BrandLogo } from "@/components/brand-logo";
import { signOut } from "@/app/auth/actions";
import { destinationForCapabilities } from "@/lib/access";
import { createClient } from "@/lib/supabase/server";
import { redirect } from "next/navigation";

export default async function StaffHome() {
  const supabase = await createClient();
  const { data } = supabase ? await supabase.auth.getClaims() : { data: null };
  if (supabase) {
    const { data: capabilities } = await supabase.rpc("tebelopele_my_capabilities");
    if (destinationForCapabilities(Array.isArray(capabilities) ? capabilities : []) !== "/staff") {
      redirect("/client");
    }
  }
  const email = String(data?.claims?.email ?? "Staff member");

  return (
    <main className="staff-foundation">
      <header><Link href="/"><BrandLogo compact/></Link><form action={signOut}><button className="button button--quiet"><LogOut size={18}/> Sign out</button></form></header>
      <section className="staff-intro"><div><p className="welcome-line">Staff workspace</p><h1>Welcome to the Tebelopele operations foundation.</h1><p>Role, facility and skill assignments will determine the work available to each staff member.</p></div><span className="user-chip"><span>{email.slice(0,1).toUpperCase()}</span>{email}</span></section>
      <section className="staff-status"><div><BadgeCheck/><h2>Access controlled</h2><p>Capabilities and Row Level Security protect staff operations.</p></div><div><UsersRound/><h2>Skills ready</h2><p>The schema supports verified skills, proficiency, languages and availability.</p></div><div><BriefcaseMedical/><h2>Workflows staged</h2><p>Appointments, content and support queues arrive in their planned phases.</p></div></section>
    </main>
  );
}
