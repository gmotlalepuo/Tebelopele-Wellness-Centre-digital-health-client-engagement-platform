# Phase 1 foundation

## Implemented

- Next.js App Router with strict TypeScript, Tailwind CSS, ESLint, Vitest and CI.
- Logo-derived Tebelopele design tokens, supplied logo asset, favicon, responsive public shell, sign-in/reset screens, client portal shell and capability-guarded staff shell.
- Supabase browser/server clients, request-time session refresh and protected portal routing.
- Email/password sign-in, sign-out, password-reset request and authorization callback.
- `tebelopele_` identity, role/capability, facility, staff profile, skill and audit schema.
- Default-deny grants and RLS policies, restricted self-service profile columns, new-user profile trigger and capability-based staff routing.
- Fictional seed roles, capabilities, staff-routing skills and one clearly named demonstration facility.

## Local setup

1. Install packages with `npm ci`.
2. Copy `.env.example` to `.env.local` and set the public Supabase URL and anon key. Keep the service-role key server-side and leave it unset unless a later server operation explicitly needs it.
3. Start Docker Desktop, then run `npx supabase start` and `npx supabase db reset` for the local database.
4. Run `npm run dev` and open `http://localhost:3000`.

Set `TEBELOPELE_PREVIEW_MODE=1` only for local interface review when you want to render clearly labelled sample public content without contacting the configured Supabase project.

Supabase email sign-up is disabled in `supabase/config.toml`. Create clients through the future onboarding flow and staff through the future invitation workflow. For local development, users may be created through Supabase Studio, then assigned a seeded role with an administrator-owned SQL operation.

## Verification

Run `npm run lint`, `npm run typecheck`, `npm test` and `npm run build`. Browser checks cover the desktop home page, responsive mobile menu, mobile sign-in layout and safe missing-Supabase error state. Apply and exercise the migration against a local or connected Supabase project before treating database behavior as runtime-verified.

## Current boundary

The public links and authenticated shells identify later-phase features without presenting fictional operational data. Phase 2 supplies services, facilities, content and client-profile workflows. Phase 3 supplies appointments. Phase 6 supplies live human support. External AI and WhatsApp credentials are not required for this phase.
