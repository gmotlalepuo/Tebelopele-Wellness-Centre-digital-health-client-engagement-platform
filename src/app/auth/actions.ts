"use server";

import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { destinationForCapabilities } from "@/lib/access";
import { getApplicationMemberships } from "@/lib/application-memberships";

function safeNext(value: FormDataEntryValue | null) {
  return typeof value === "string" && value.startsWith("/") && !value.startsWith("//")
    ? value
    : null;
}

export async function signIn(formData: FormData) {
  const supabase = await createClient();
  if (!supabase) redirect("/sign-in?error=setup");

  const email = String(formData.get("email") ?? "").trim();
  const password = String(formData.get("password") ?? "");
  const requestedDestination = safeNext(formData.get("next"));
  const { error } = await supabase.auth.signInWithPassword({ email, password });

  if (error) {
    const query = requestedDestination ? `&next=${encodeURIComponent(requestedDestination)}` : "";
    redirect(`/sign-in?error=credentials${query}`);
  }

  const {data:claims}=await supabase.auth.getClaims();
  const userId=String(claims?.claims?.sub??"");
  const applications=userId?await getApplicationMemberships(userId):[];
  if(applications.length>1)redirect("/choose-application");
  if(applications.length===1&&applications[0].id!=="tebelopele")redirect("/choose-application");

  const { data: profile } = await supabase
    .from("tebelopele_profiles")
    .select("account_status")
    .eq("id", userId)
    .single();
  if (profile?.account_status !== "active") {
    await supabase.auth.signOut();
    redirect("/sign-in?error=inactive");
  }

  const { data: capabilities } = await supabase.rpc("tebelopele_my_capabilities");
  const assignedCapabilities = Array.isArray(capabilities) ? capabilities : [];
  const permittedDestination = destinationForCapabilities(assignedCapabilities);
  const destination = requestedDestination === "/staff" && permittedDestination !== "/staff"
    ? "/client"
    : (requestedDestination ?? permittedDestination);
  redirect(destination);
}

export async function requestPasswordReset(formData: FormData) {
  const supabase = await createClient();
  if (!supabase) redirect("/forgot-password?error=setup");

  const email = String(formData.get("email") ?? "").trim();
  const appUrl = process.env.NEXT_PUBLIC_APP_URL ?? "http://localhost:3000";
  await supabase.auth.resetPasswordForEmail(email, {
    redirectTo: `${appUrl}/auth/callback?next=/client`,
  });
  redirect("/forgot-password?sent=1");
}

export async function signOut() {
  const supabase = await createClient();
  if (supabase) await supabase.auth.signOut();
  redirect("/");
}
