# Integration contracts to finalize with providers

## External AI service

`POST /v1/chat/answer` is a proposed contract, not a claim about an existing endpoint. Next.js authenticates the request server to server. The AI service accepts a correlation ID, conversation ID, message ID, language, intent context, scoped evidence/source IDs and a bounded current question. Avoid sending full transcript or personal health data unless approved. It returns `answer`, `source` (`verified`, `verified_ai`, `live_data`, `assistant`, `no_evidence`), exact `citations` with source/version/chunk IDs, `requires_human`, safe reason code, model ID (`qwen2.5` variant), and latency. The product rejects unsupported citation IDs and persists the validated response in the canonical transcript. Timeout, retry/idempotency and provider outage behavior are contract tests. The actual URL, auth scheme, supported model variant, embedding owner, data retention and region are pending.

## WhatsApp provider

Provider webhook must include signed event authentication, provider event/message ID, sender/channel identity, timestamp, message type, text or selected option ID, and delivery status. The adapter validates signature, deduplicates IDs, maps an inbound event to a conversation, advances a versioned menu state and sends a response through an outbound provider API. Basic menu branches: services, facilities/hours, appointments, approved health information, referrals, and talk to a person. Free text may route to AI only under the same knowledge/safety policy as web chat. Webhook acknowledgement occurs before slow work; durable processing handles retries. During takeover, inbound messages go to the assigned support queue and menu/AI responses remain paused. Provider, account, template approvals, 24-hour rules, identity verification and video flow examples remain pending.

## Support assignment

An escalation creates or reuses one active case per conversation. Routing filters active staff by approved skill, facility, language, role and availability; it ranks proficiency and workload, then offers or assigns according to policy. An agent must explicitly accept/claim where required. Reassignment records reason and actor. A case keeps status (`open`, `assigned`, `waiting_user`, `resolved`, `closed`), priority and due time. Public agent replies append to the conversation; private notes stay in a separate restricted store. Client and agent see a clear control-state change. Urgent clinical statements use Tebelopele-approved rules and wording, never a model-only urgency decision.

## Booking and notifications

If Tebelopele has an appointment system, its slot/booking API is authoritative. A server adapter maps local IDs to external IDs, normalizes statuses, and uses idempotency keys. Notifications have template version, recipient consent/preference, delivery attempt, provider ID and status. Medication reminders require an approved data source and workflow before activation.

Each integration needs an owner, sandbox, endpoint specification, credentials in environment secrets, data fields/classification, rate limits, timeout/retry policy, failure path and UAT scenarios before activation.
