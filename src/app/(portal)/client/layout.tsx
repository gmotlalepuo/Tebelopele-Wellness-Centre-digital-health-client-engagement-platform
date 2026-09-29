import type { ReactNode } from "react";
import { AppShell } from "@/components/app-shell";
import { getClientContext } from "@/lib/client-data";
import { getRoleContext } from "@/lib/role-context";

export default async function ClientLayout({ children }: { children: ReactNode }) {
  const [client, roles] = await Promise.all([getClientContext(), getRoleContext()]);
  return <AppShell name={client.displayName} activeRole={roles.activeRole} assignedRoles={roles.assignedRoles}>{children}</AppShell>;
}
