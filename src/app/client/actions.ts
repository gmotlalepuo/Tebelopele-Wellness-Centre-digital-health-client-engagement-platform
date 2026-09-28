"use server";

import { redirect } from "next/navigation";
import { z } from "zod";
import { createClient } from "@/lib/supabase/server";

async function authenticatedClient() {
  const supabase = await createClient();
  if (!supabase) return null;
  const { data } = await supabase.auth.getClaims();
  const userId = typeof data?.claims?.sub === "string" ? data.claims.sub : null;
  return userId ? { supabase, userId } : null;
}

const profileSchema = z.object({
  displayName: z.string().trim().min(1).max(120),
  preferredName: z.string().trim().max(120),
  phone: z.string().trim().max(30),
  dateOfBirth: z.string().regex(/^$|^\d{4}-\d{2}-\d{2}$/),
});

export async function updateClientProfile(formData: FormData) {
  const context = await authenticatedClient();
  if (!context) redirect("/client/profile?error=setup");
  const parsed = profileSchema.safeParse({ displayName: formData.get("display_name"), preferredName: formData.get("preferred_name"), phone: formData.get("phone"), dateOfBirth: formData.get("date_of_birth") });
  if (!parsed.success) redirect("/client/profile?error=validation");
  const { supabase } = context;
  const { error } = await supabase.rpc("tebelopele_update_own_client_profile", {
    profile_display_name: parsed.data.displayName,
    client_preferred_name: parsed.data.preferredName,
    profile_phone: parsed.data.phone,
    client_date_of_birth: parsed.data.dateOfBirth || null,
  });
  if (error) redirect("/client/profile?error=save");
  redirect("/client/profile?saved=1");
}

const preferencesSchema = z.object({
  preferredLanguage: z.enum(["en", "tn"]),
  preferredChannel: z.enum(["in_app", "email", "sms", "whatsapp"]),
});

export async function updateCommunicationPreferences(formData: FormData) {
  const context = await authenticatedClient();
  if (!context) redirect("/client/preferences?error=setup");
  const parsed = preferencesSchema.safeParse({ preferredLanguage: formData.get("preferred_language"), preferredChannel: formData.get("preferred_channel") });
  if (!parsed.success) redirect("/client/preferences?error=validation");
  const { error } = await context.supabase.from("tebelopele_client_preferences").upsert({ client_user_id: context.userId, preferred_language: parsed.data.preferredLanguage, preferred_channel: parsed.data.preferredChannel, allow_email: formData.get("allow_email") === "on", allow_sms: formData.get("allow_sms") === "on", allow_whatsapp: formData.get("allow_whatsapp") === "on" });
  if (error) redirect("/client/preferences?error=save");
  redirect("/client/preferences?saved=1");
}

export async function recordConsentDecision(formData: FormData) {
  const context = await authenticatedClient();
  if (!context) redirect("/client/consent?error=setup");
  const parsed = z.object({ consentVersionId: z.uuid(), decision: z.enum(["accepted", "declined", "withdrawn"]) }).safeParse({ consentVersionId: formData.get("consent_version_id"), decision: formData.get("decision") });
  if (!parsed.success) redirect("/client/consent?error=validation");
  const { error } = await context.supabase.from("tebelopele_client_consent_events").insert({ client_user_id: context.userId, consent_version_id: parsed.data.consentVersionId, decision: parsed.data.decision, channel: "web" });
  if (error) redirect("/client/consent?error=save");
  redirect("/client/consent?saved=1");
}
