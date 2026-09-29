import { createClient } from "@supabase/supabase-js";
import { randomBytes } from "node:crypto";
import { writeFile } from "node:fs/promises";

const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
const serviceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
if (!url || !serviceKey) throw new Error("Supabase administration environment is not configured");

const supabase = createClient(url, serviceKey, { auth: { persistSession: false, autoRefreshToken: false } });
const email = "tebelopele.demo.superuser@example.com";
const displayName = "Tebelopele Demo Superuser";
const password = `Tb!${randomBytes(14).toString("base64url")}9a`;

async function must(promise, label) {
  const { data, error } = await promise;
  if (error) throw new Error(`${label}: ${error.message}`);
  return data;
}

const roles = await must(supabase.from("tebelopele_roles").select("id,slug"), "read roles");
const skills = await must(supabase.from("tebelopele_skills").select("id,slug").eq("is_active", true), "read skills");
if (!roles.length) throw new Error("No Tebelopele roles are configured");

let authUser = null;
for (let page = 1; !authUser; page += 1) {
  const result = await must(supabase.auth.admin.listUsers({ page, perPage: 100 }), "list users");
  authUser = result.users.find((user) => user.email === email) ?? null;
  if (result.users.length < 100) break;
}

const authResult = authUser
  ? await must(supabase.auth.admin.updateUserById(authUser.id, { password, email_confirm: true, user_metadata: { app: "tebelopele", display_name: displayName, demo_superuser: true } }), "update superuser")
  : await must(supabase.auth.admin.createUser({ email, password, email_confirm: true, user_metadata: { app: "tebelopele", display_name: displayName, demo_superuser: true } }), "create superuser");
const userId = authResult.user.id;

await must(supabase.from("tebelopele_profiles").upsert({ id: userId, display_name: displayName, account_status: "active" }, { onConflict: "id" }), "upsert profile");
await must(supabase.from("tebelopele_user_roles").delete().eq("user_id", userId), "clear roles");
await must(supabase.from("tebelopele_user_roles").insert(roles.map((role) => ({ user_id: userId, role_id: role.id }))), "assign all roles");
await must(supabase.from("tebelopele_clients").upsert({ user_id: userId, preferred_name: "Superuser" }, { onConflict: "user_id" }), "upsert client profile");
await must(supabase.from("tebelopele_client_preferences").upsert({ client_user_id: userId, preferred_language: "en", preferred_channel: "in_app" }, { onConflict: "client_user_id" }), "upsert client preferences");
await must(supabase.from("tebelopele_staff_profiles").upsert({ user_id: userId, staff_number: "DEMO-SUPER-001", job_title: "Demonstration superuser", availability: "available", languages: ["en", "tn"], max_active_cases: 100, is_accepting_cases: true }, { onConflict: "user_id" }), "upsert staff profile");
await must(supabase.from("tebelopele_staff_skills").delete().eq("staff_user_id", userId), "clear skills");
if (skills.length) await must(supabase.from("tebelopele_staff_skills").insert(skills.map((skill) => ({ staff_user_id: userId, skill_id: skill.id, proficiency: "expert", is_verified: true, verified_by: userId, verified_at: new Date().toISOString() }))), "assign all skills");

const credential = { generatedAt: new Date().toISOString(), warning: "Demonstration superuser. Rotate or remove before launch.", email, password, roles: roles.map((role) => role.slug).sort(), skills: skills.map((skill) => skill.slug).sort() };
await writeFile(".superuser.local.json", JSON.stringify(credential, null, 2));
console.log(JSON.stringify({ createdOrUpdated: email, roleCount: credential.roles.length, skillCount: credential.skills.length, credentialFile: ".superuser.local.json" }));
