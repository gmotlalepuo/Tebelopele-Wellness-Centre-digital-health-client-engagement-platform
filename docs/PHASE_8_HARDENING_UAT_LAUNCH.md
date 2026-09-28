# Phase 8 — Hardening, UAT and launch readiness

## Implemented foundation

- WCAG-oriented landmarks, skip links, focus visibility, minimum target sizing, labelled forms, non-colour status labels and reduced-motion handling.
- Responsive staff reporting, referral and administration layouts for narrow screens.
- Server-side validation for referral/configuration mutations and repeated capability checks close to data access.
- A public privacy-notice route for formal legal/privacy review.
- No-store, permission-scoped operational export.
- Empty and preview states that do not present invented operational data.
- Deployment, incident, backup/restore and UAT runbooks below.

## Release gates still requiring accountable sign-off

1. Apply all Supabase migrations in a staging project and run the RLS role matrix.
2. Obtain legal/privacy approval for the privacy and consent wording, including approved contact details.
3. Complete keyboard, screen-reader and 200% zoom testing on supported mobile and desktop browsers.
4. Run performance tests on representative Botswana mobile connectivity and agreed concurrency.
5. Run Qwen 2.5 safety/evaluation cases through the external AI endpoint once supplied.
6. Restore a production-like backup into an isolated project and record recovery time/evidence.
7. Complete business UAT and obtain named sign-off.
8. Agree launch owner, rollback decision-maker, incident contacts and post-launch support window.

Software completion is not the same as operational approval. These evidence-dependent gates remain open until Tebelopele owners sign them.
