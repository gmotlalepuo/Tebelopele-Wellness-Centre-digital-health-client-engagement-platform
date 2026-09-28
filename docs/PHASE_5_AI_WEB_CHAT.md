# Phase 5 — AI web chat

## Delivered

- Authenticated, persistent web conversations and one append-only transcript.
- Server-only `POST /v1/chat/answer` adapter for a Qwen 2.5 external service.
- Approved knowledge retrieval with exact article, version and chunk evidence.
- Strict response schema and rejection of citations outside the supplied evidence set.
- Deterministic urgent-language interception before model inference.
- Safe no-evidence, timeout, malformed-response and provider-outage behavior.
- Per-user database-backed rate limiting, request idempotency and correlation IDs.
- Source labels, clickable approved sources, helpful/not-helpful feedback and human escalation.
- Preview mode that never calls an external model and clearly labels fictional content.

## External AI configuration

Configure only in the server environment:

- `TEBELOPELE_AI_BASE_URL`
- `TEBELOPELE_AI_API_KEY`
- `TEBELOPELE_AI_TIMEOUT_MS` (optional; defaults to 12000)

The browser never receives these values. Production activation still requires the final endpoint, authentication scheme, exact Qwen 2.5 variant, region, retention agreement, rate limits and approved clinical safety wording.

## Acceptance boundary

Local tests prove the response contract, citation allow-list and deterministic urgent rule. A sandbox must still prove Qwen timeout/retry behavior, citation accuracy and the evaluation set against indexed approved content.

