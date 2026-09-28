import { createServerClient } from "@supabase/ssr";
import { NextResponse, type NextRequest } from "next/server";
import { getPublicEnvironment } from "@/lib/env";

export async function updateSession(request: NextRequest) {
  if (process.env.NODE_ENV !== "production" && process.env.TEBELOPELE_PREVIEW_MODE === "1") {
    return NextResponse.next({ request });
  }
  const environment = getPublicEnvironment();
  if (!environment) return NextResponse.next({ request });

  let response = NextResponse.next({ request });
  const supabase = createServerClient(
    environment.NEXT_PUBLIC_SUPABASE_URL,
    environment.NEXT_PUBLIC_SUPABASE_ANON_KEY,
    {
      cookies: {
        getAll: () => request.cookies.getAll(),
        setAll: (cookiesToSet) => {
          cookiesToSet.forEach(({ name, value }) => request.cookies.set(name, value));
          response = NextResponse.next({ request });
          cookiesToSet.forEach(({ name, value, options }) =>
            response.cookies.set(name, value, options),
          );
        },
      },
    },
  );

  const { data } = await supabase.auth.getClaims();
  const protectedPath = request.nextUrl.pathname.startsWith("/client") ||
    request.nextUrl.pathname.startsWith("/staff");

  if (protectedPath && !data?.claims) {
    const url = request.nextUrl.clone();
    url.pathname = "/sign-in";
    url.searchParams.set("next", request.nextUrl.pathname);
    return NextResponse.redirect(url);
  }

  return response;
}
