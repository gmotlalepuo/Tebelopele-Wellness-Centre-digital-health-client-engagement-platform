import type { ReactNode } from "react";
import { AppShell } from "@/components/app-shell";
import { getClientContext } from "@/lib/client-data";

export default async function ClientLayout({ children }: { children: ReactNode }) {
  const client = await getClientContext();
  return <AppShell name={client.displayName}>{children}</AppShell>;
}
