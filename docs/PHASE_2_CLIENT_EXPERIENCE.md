# Phase 2 public and client experience

## Implemented public experience

- Responsive service directory and service detail routes.
- Facility/service-point directory with hours, contact details and available services.
- Health-information index and readable article pages.
- Accessible FAQ disclosures.
- Cross-domain public search over services, articles and FAQs.
- Shared public header, footer, search, skip navigation, loading, empty, error and not-found states.
- A development-only preview mode that labels every sample record and is disabled in production builds.

## Implemented client experience

- Client overview with direct routes to published locations, profile and preferences.
- Profile editing for display/preferred name, mobile number and optional date of birth.
- Atomic profile/client/contact persistence through an RLS-protected PostgreSQL function.
- Language, preferred-channel and email/SMS/WhatsApp permission settings.
- Versioned consent notices and append-only accept, decline and withdrawal events.
- Database validation that prevents consent against inactive versions and prevents withdrawal without a prior acceptance.
- Responsive authenticated navigation and safe unconfigured/empty states.

## Data and access controls

Migration `20260928000200_phase_2_client_experience.sql` adds services, facility hours and service availability, outreach, content categories, versioned health articles/FAQs, client details, contacts, preferences, consent versions and consent events. Anonymous access is limited to records explicitly published for public visibility. Clients can manage only rows keyed to their authenticated user ID. Consent events cannot be updated or deleted through the client role.

The migration extends the Phase 1 facility record instead of creating a second location concept. Article and FAQ versions are introduced now so Phase 4 governance can add review, attachments and indexing without replacing the public content model.

## Local review

Set `TEBELOPELE_PREVIEW_MODE=1` when running `npm run dev` to render clearly labelled sample content without querying Supabase. The flag is ignored by production builds. The local seed file contains separate fictional records for database and RLS testing; they are visibly named as demonstrations.

## Verification and remaining runtime gate

Lint, strict TypeScript, unit tests, production build and browser checks cover the public directory, mobile locations, FAQ disclosure, search, client overview and disabled client-form preview. Docker is not running and the configured `.env.local` may point at an unrelated existing Supabase project, so the Phase 2 migration has not been applied. Execute the migrations in an approved local/UAT Supabase environment and run authenticated cross-user/RLS tests before accepting database runtime behaviour.

Phase 3 adds appointment availability, booking, rescheduling, cancellation and notification delivery. Phase 4 adds the editorial governance and ingestion workspace around the content/version tables introduced here.
