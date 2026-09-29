"use server";

import { cookies } from "next/headers";
import { redirect } from "next/navigation";
import { activeRoleCookie, getRoleContext } from "@/lib/role-context";
import { isRoleSlug, rolePresentation } from "@/lib/roles";

export async function switchRole(formData: FormData) {
  const requested = String(formData.get("role") ?? "");
  const context = await getRoleContext();
  if (!isRoleSlug(requested) || !context.assignedRoles.includes(requested)) {
    redirect(context.activeRole === "client" ? "/client" : "/staff");
  }

  (await cookies()).set(activeRoleCookie, requested, {
    httpOnly: true,
    sameSite: "lax",
    secure: process.env.NODE_ENV === "production",
    path: "/",
    maxAge: 60 * 60 * 8,
  });
  redirect(rolePresentation[requested].destination);
}
