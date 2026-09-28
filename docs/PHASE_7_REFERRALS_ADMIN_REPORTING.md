# Phase 7 — Referrals, administration and reporting

## Delivered scope

- Referral register with client, service, origin, destination, urgency, consent confirmation, owner and follow-up scheduling.
- Database-controlled status transitions: draft → pending → accepted → scheduled → completed, with declined/cancelled exits.
- Append-only transition history, follow-up outcomes and audit events.
- Staff referral queue and detail workspace.
- Role-scoped operational dashboard and CSV export. No demonstration totals are presented as real metrics.
- System settings register that excludes sensitive credentials from the browser.
- Audit-event register and recent WhatsApp provider-processing health.
- Administration routes to governed content and operational directories.

## Authorization model

`referrals.manage`, `reports.read`, `audit.read` and `system.manage` are checked at the page/action boundary and again through Supabase Row Level Security. The CSV handler repeats authorization independently. Database functions validate transitions and write audit records atomically.

## Deployment gate

Apply `20260928000700_phase_7_referrals_reporting.sql` to the target Supabase project, assign the required roles, and complete an authorized referral lifecycle test. Dashboard values must be reconciled against source records for each test role before operational approval.

## Acceptance evidence required

- Referral officer can move a referral only through valid transitions.
- Unauthorized staff cannot read or export referral records.
- Follow-up history identifies actor and time.
- Report counts and export rows reconcile with visible source records.
- Audit and integration-health pages expose only authorized records.
