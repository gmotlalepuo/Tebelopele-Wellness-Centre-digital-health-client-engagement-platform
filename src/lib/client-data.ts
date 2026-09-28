import { createClient } from "@/lib/supabase/server";

export type ClientContext = {
  configured: boolean;
  userId: string | null;
  email: string;
  displayName: string;
  phone: string;
  preferredName: string;
  dateOfBirth: string;
  preferences: {
    preferredLanguage: string;
    preferredChannel: string;
    allowEmail: boolean;
    allowSms: boolean;
    allowWhatsapp: boolean;
  };
};

export async function getClientContext(): Promise<ClientContext> {
  if (process.env.NODE_ENV !== "production" && process.env.TEBELOPELE_PREVIEW_MODE === "1") return { configured: false, userId: null, email: "", displayName: "Client", phone: "", preferredName: "", dateOfBirth: "", preferences: { preferredLanguage: "en", preferredChannel: "in_app", allowEmail: false, allowSms: false, allowWhatsapp: false } };
  const supabase = await createClient();
  if (!supabase) return { configured: false, userId: null, email: "", displayName: "Client", phone: "", preferredName: "", dateOfBirth: "", preferences: { preferredLanguage: "en", preferredChannel: "in_app", allowEmail: false, allowSms: false, allowWhatsapp: false } };
  const { data: claimsData } = await supabase.auth.getClaims();
  const userId = typeof claimsData?.claims?.sub === "string" ? claimsData.claims.sub : null;
  const email = typeof claimsData?.claims?.email === "string" ? claimsData.claims.email : "";
  if (!userId) return { configured: true, userId: null, email, displayName: "Client", phone: "", preferredName: "", dateOfBirth: "", preferences: { preferredLanguage: "en", preferredChannel: "in_app", allowEmail: false, allowSms: false, allowWhatsapp: false } };
  const [{ data: profile }, { data: client }, { data: preferences }] = await Promise.all([
    supabase.from("tebelopele_profiles").select("display_name,phone").eq("id", userId).maybeSingle(),
    supabase.from("tebelopele_clients").select("preferred_name,date_of_birth").eq("user_id", userId).maybeSingle(),
    supabase.from("tebelopele_client_preferences").select("preferred_language,preferred_channel,allow_email,allow_sms,allow_whatsapp").eq("client_user_id", userId).maybeSingle(),
  ]);
  return {
    configured: true,
    userId,
    email,
    displayName: profile?.display_name ?? email.split("@")[0] ?? "Client",
    phone: profile?.phone ?? "",
    preferredName: client?.preferred_name ?? "",
    dateOfBirth: client?.date_of_birth ?? "",
    preferences: {
      preferredLanguage: preferences?.preferred_language ?? "en",
      preferredChannel: preferences?.preferred_channel ?? "in_app",
      allowEmail: preferences?.allow_email ?? false,
      allowSms: preferences?.allow_sms ?? false,
      allowWhatsapp: preferences?.allow_whatsapp ?? false,
    },
  };
}

export async function getConsentContext() {
  if (process.env.NODE_ENV !== "production" && process.env.TEBELOPELE_PREVIEW_MODE === "1") return { configured: false, versions: [], latest: new Map<string, string>() };
  const supabase = await createClient();
  if (!supabase) return { configured: false, versions: [], latest: new Map<string, string>() };
  const { data: claimsData } = await supabase.auth.getClaims();
  const userId = typeof claimsData?.claims?.sub === "string" ? claimsData.claims.sub : null;
  if (!userId) return { configured: true, versions: [], latest: new Map<string, string>() };
  const [{ data: versions }, { data: events }] = await Promise.all([
    supabase.from("tebelopele_consent_versions").select("id,consent_type,version_number,title,summary,full_text,effective_at").is("retired_at", null).order("consent_type"),
    supabase.from("tebelopele_client_consent_events").select("consent_version_id,decision,occurred_at").eq("client_user_id", userId).order("occurred_at", { ascending: false }),
  ]);
  const latest = new Map<string, string>();
  for (const event of events ?? []) if (!latest.has(event.consent_version_id)) latest.set(event.consent_version_id, event.decision);
  return { configured: true, versions: versions ?? [], latest };
}
