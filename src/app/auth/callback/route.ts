import { NextResponse, type NextRequest } from "next/server";
import { createClient } from "@/lib/supabase/server";

export async function GET(request: NextRequest) {
  const code = request.nextUrl.searchParams.get("code");
  const nextValue = request.nextUrl.searchParams.get("next");
  const next = nextValue?.startsWith("/") && !nextValue.startsWith("//")
    ? nextValue
    : "/client";

  if (code) {
    const supabase = await createClient();
    const result = supabase ? await supabase.auth.exchangeCodeForSession(code) : null;
    if (result && !result.error) return NextResponse.redirect(new URL(next, request.url));
  }

  return NextResponse.redirect(new URL("/sign-in?error=callback", request.url));
}
