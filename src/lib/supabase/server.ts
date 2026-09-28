import { createServerClient } from "@supabase/ssr";
import { cookies } from "next/headers";
import { getPublicEnvironment } from "@/lib/env";

export async function createClient() {
  const environment = getPublicEnvironment();
  if (!environment) return null;

  const cookieStore = await cookies();

  return createServerClient(
    environment.NEXT_PUBLIC_SUPABASE_URL,
    environment.NEXT_PUBLIC_SUPABASE_ANON_KEY,
    {
      cookies: {
        getAll: () => cookieStore.getAll(),
        setAll: (cookiesToSet) => {
          try {
            cookiesToSet.forEach(({ name, value, options }) =>
              cookieStore.set(name, value, options),
            );
          } catch {
            // Server Components cannot set cookies. The proxy refreshes sessions.
          }
        },
      },
    },
  );
}
