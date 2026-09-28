import { createBrowserClient } from "@supabase/ssr";
import { getPublicEnvironment } from "@/lib/env";

export function createClient() {
  const environment = getPublicEnvironment();

  if (!environment) {
    throw new Error("Supabase public environment variables are not configured.");
  }

  return createBrowserClient(
    environment.NEXT_PUBLIC_SUPABASE_URL,
    environment.NEXT_PUBLIC_SUPABASE_ANON_KEY,
  );
}
