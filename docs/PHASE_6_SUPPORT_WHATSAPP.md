# Phase 6 — Human support and WhatsApp

## Delivered

- Shared web/WhatsApp conversation and message records.
- One active support case per conversation with priority, SLA due time and append-only events.
- Routing requirements for verified skill, language, availability, facility-ready schema and workload limits.
- Explicit agent claim/takeover, public replies, resolve/release and transcript continuity.
- Private notes stored separately and excluded from client and AI transcript access.
- Staff routing profile for availability, languages, workload and verified skills.
- Signed WhatsApp webhook, unique provider-event/message IDs, delivery receipts and persistent flow state.
- Versioned guided menu with stable option IDs, `menu`/`start`/`0` reset and numbered fallback.
- Identity gate for private profile branches and automation pause during human takeover.
- Interactive local business-portal preview based on the supplied WhatsApp reference video.

## WhatsApp server configuration

- `WHATSAPP_PROVIDER`
- `WHATSAPP_WEBHOOK_SECRET`
- `WHATSAPP_VERIFY_TOKEN`
- `SUPABASE_SERVICE_ROLE_KEY` for the narrowly scoped webhook worker

No default secrets are present. Live outbound delivery remains disabled until the provider and outbound API contract are supplied. Production activation also requires approved templates, business account, 24-hour messaging rules, phone identity policy, escalation hours and privacy wording.

## Operational acceptance

In the provider sandbox, demonstrate duplicate delivery handling, menu state recovery, private-branch identity denial, escalation reuse, skill-qualified claim, transcript handoff, private-note isolation, agent response delivery and automation release.

