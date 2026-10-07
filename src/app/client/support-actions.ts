"use server";

import { redirect } from "next/navigation";
import { z } from "zod";
import { createClient } from "@/lib/supabase/server";

const supportRequestSchema = z.object({
  topic: z.enum(["general_navigation", "appointment_support", "content_guidance", "referral_navigation", "technical_support"]),
  language: z.enum(["en", "tn"]),
  message: z.string().trim().min(10).max(1500),
});

export async function requestHumanSupport(formData: FormData) {
  const parsed = supportRequestSchema.safeParse({
    topic: formData.get("topic"),
    language: formData.get("language"),
    message: formData.get("message"),
  });
  if (!parsed.success) redirect("/client/support?error=validation");

  const supabase = await createClient();
  if (!supabase) redirect("/client/support?error=setup");

  const { data, error } = await supabase.rpc("tebelopele_request_human_support", {
    required_skill_slug: parsed.data.topic,
    preferred_language: parsed.data.language,
    request_message: parsed.data.message,
  });
  const result = Array.isArray(data) ? data[0] : data;
  if (error || !result?.conversation_id) redirect("/client/support?error=route");

  redirect(`/client/support?requested=1&conversation=${result.conversation_id}`);
}
