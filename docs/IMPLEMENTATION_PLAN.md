# Implementation plan

## Scope and delivery rule

The product serves public visitors, clients, support and clinical staff, content editors/reviewers, reception, referral officers, administrators and auditors. Each phase ends with a working demonstration and its stated acceptance gate. A screen alone does not complete a feature: authorization, responsive behavior, errors, empty/loading states, accessibility, audit, tests and documentation are part of its gate. Production release is conditional on Tebelopele's clinical, privacy and operational approval.

| Phase | Implementation | Demonstration and gate |
| --- | --- | --- |
| 0. Discovery and design | Confirm journeys, facilities/services, booking ownership, consent, languages, retention, escalation, WhatsApp provider, AI endpoint and hosting. Map requirements, entities, permissions and contracts. Establish logo-derived visual direction and accessibility target. | Signed decision log, architecture/data/API review, prioritized backlog, representative user journeys and acceptance scenarios. Block only dependent workflows when external decisions are outstanding. |
| 1. Foundation | Initialize Next.js/TypeScript; quality checks and environment templates; Supabase local migration workflow; Auth; profiles, staff roles, capabilities, facilities and skills; RLS; server-side audit events; app shell and responsive brand tokens; fictional seed data. | Client and staff can sign in to appropriate shells. Cross-user reads and unauthorized writes fail at database/API layers. No server secret reaches a browser bundle. |
| 2. Public and client experience | Public home, services, facilities, hours, outreach and approved content; client onboarding/profile, contact preferences and versioned consent; search and accessible mobile navigation. | Visitor finds a service and facility; client updates own permitted details; withdrawn consent blocks affected processing. Only published content appears publicly. |
| 3. Appointments and notifications | Availability source adapter; service/location/slot choice; booking, reschedule and cancel rules; staff calendar and status history; opt-in templates, reminder schedule, delivery attempts and retries. | A real or sandbox booking completes end to end without slot collision; cancellation and reminders update consistently; external calendar ownership is respected if present. |
| 4. Governed knowledge | Article/FAQ categories, immutable versions, private file storage, review comments, exact-version approval, publication/withdrawal, audit; durable extraction/index jobs; permission-filtered hybrid retrieval and retrieval test console. | One document travels upload → review → approval → index → cited retrieval. A draft or restricted document never appears in an unauthorized answer. |
| 5. AI web chat | Authenticated chat API and shared transcript; server-to-server external Qwen 2.5 adapter; deterministic FAQ/service routing, grounded response/citation checks, source labels, feedback, rate limits, safe failure behavior and evaluation set. | Approved answers cite exact versions; unsupported or urgent questions follow approved response/escalation rules; provider outage preserves the conversation and offers human help. |
| 6. Human support and WhatsApp | Staff skill profiles with proficiency, facility/language, availability and assignment permissions; queue and skill-based routing; accept/reassign/takeover, public replies, private notes, transcript continuity, case states and SLA; WhatsApp webhook, guided menu flows, template management, delivery receipts, identity checks and human handoff. | Web and WhatsApp cases route to an eligible human; the agent sees permitted prior dialogue; once taken over, AI/preset replies stop until explicit release. Duplicate webhooks/escalations do not duplicate messages or cases. |
| 7. Referrals, administration and reporting | Approved referral routes/statuses/follow-up; admin management of services/facilities/staff/content/configuration; operational dashboards, audit and integration health, permission-scoped exports. | Referral can be created, followed and closed by authorized roles; dashboard numbers trace to real records and respect access scope. |
| 8. Hardening, UAT and launch | Security/privacy review, RLS regression, accessibility target WCAG 2.2 AA, mobile/low-bandwidth performance, load and AI safety evaluation, backup/restore rehearsal, UAT fixes, production runbooks, training, monitoring and handover. | Tebelopele signs UAT; backup restoration and incident path demonstrated; launch checklist, owner, rollback and post-launch support agreed. |

## Dependencies and release slices

Phase 1 may begin while Phase 0 decisions are collected. Phase 3 booking cannot use live availability until its source of truth is known. Phase 5 factual health answers depend on Phase 4 approved retrieval. Phase 6 WhatsApp production activation depends on provider credentials, webhook access, templates and approved privacy/identity rules. Phase 8 is a release gate, not a substitute for testing in earlier phases.

First demonstrable vertical slice: a fictional service/facility is displayed publicly; a fictional client signs in, requests an appointment, asks a question from an approved FAQ, escalates, and receives a staff reply in the same transcript. WhatsApp follows the same support case after its provider sandbox is available.

## Requirements traceability

| Requirement | Delivery phase | Acceptance evidence |
| --- | --- | --- |
| Public service and facility access | 2 | Mobile journey and published-content check |
| Private client account and consent | 1–2 | Auth/RLS and withdrawal checks |
| Appointment lifecycle/reminders | 3 | Slot concurrency, state and delivery checks |
| Governed knowledge/FAQ | 4 | Version approval and restricted retrieval checks |
| External Qwen 2.5 chat | 5 | Contract and outage tests; citations/evaluation report |
| Skill-routed human takeover | 1, 6 | Assignment, transcript and private-note tests |
| WhatsApp guided interaction | 6 | Sandbox menu, webhook idempotency and handoff tests |
| Referral management | 7 | Role-scoped lifecycle test |
| Reporting/audit | 1, 7 | Audit sampling and permission-scoped dashboard test |
| Accessibility, privacy and operations | Every phase, 8 | Automated/manual audit, restore rehearsal and UAT sign-off |
