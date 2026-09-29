import "server-only";

import { cookies } from "next/headers";
import { createClient } from "@/lib/supabase/server";
import { isRoleSlug, type RoleSlug } from "@/lib/roles";

const ACTIVE_ROLE_COOKIE = "tebelopele_active_role";

export type RoleContext = { activeRole: RoleSlug; assignedRoles: RoleSlug[] };

export async function getRoleContext(): Promise<RoleContext> {
  const supabase = await createClient();
  if (!supabase) return { activeRole: "client", assignedRoles: ["client"] };

  const { data } = await supabase
    .from("tebelopele_user_roles")
    .select("role:tebelopele_roles(slug)");
  const assignedRoles = (data ?? [])
    .map((row) => {
      const role = Array.isArray(row.role) ? row.role[0] : row.role;
      return role && typeof role.slug === "string" && isRoleSlug(role.slug) ? role.slug : null;
    })
    .filter((role): role is RoleSlug => role !== null);

  const uniqueRoles = [...new Set(assignedRoles)];
  const selected = (await cookies()).get(ACTIVE_ROLE_COOKIE)?.value ?? "";
  const activeRole = isRoleSlug(selected) && uniqueRoles.includes(selected)
    ? selected
    : uniqueRoles.includes("system_administrator")
      ? "system_administrator"
      : uniqueRoles[0] ?? "client";

  return { activeRole, assignedRoles: uniqueRoles };
}

export const activeRoleCookie = ACTIVE_ROLE_COOKIE;
