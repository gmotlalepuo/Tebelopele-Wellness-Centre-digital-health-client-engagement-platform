# Phase 0 decisions and assumptions

| ID | Decision needed | Working position / impact |
| --- | --- | --- |
| D01 | Physical table prefix | Guide says `council_`; propose `tebelopele_` or a dedicated schema. Resolve before first migration. |
| D02 | Source of client identity and appointment availability | Supabase Auth is chosen for platform sign-in; existing clinical/booking system ownership remains unknown. Determines profile mapping and Phase 3 adapter. |
| D03 | Clinical scope and urgent escalation | Tebelopele clinicians approve topic boundaries, trigger rules, wording, hours and out-of-hours path. Blocks release of AI/WhatsApp health flows. |
| D04 | Content governance | Name author, reviewer and publisher roles; decide whether two-person approval is mandatory. Blocks publication workflow sign-off. |
| D05 | Privacy | Approve consent text, retention by record type, WhatsApp identity proof, staff transcript access, AI data sharing and processing regions. Blocks production activation. |
| D06 | External AI | Supply base URL, auth, Qwen 2.5 variant, embedding/retrieval ownership, OpenAPI or sample payload, limits and sandbox. Blocks live Phase 5 integration. |
| D07 | WhatsApp | Select provider/business account, webhook sandbox, approved templates and example flow/video. Blocks live Phase 6 integration. |
| D08 | Languages and content | Confirm launch languages, service/facility catalogue and approved initial health/FAQ sources. Blocks meaningful content and evaluation. |
| D09 | Channels and booking rules | Confirm SMS/email, online-bookable services, cancellation windows and reminder timing. Blocks specific Phase 3/6 behavior. |
| D10 | Operations | Confirm hosting region, expected volume, uptime/support targets, recovery objectives and reporting indicators. Shapes Phase 8 launch gate. |

Current implementation assumptions are explicitly provisional: mobile-first web; public service directory; no general AI or web-search fallback at launch; source-grounded health answers; no private record retrieval over WhatsApp without verification; administrator access to private transcripts requires explicit permission. These can be revised through a recorded decision.

## Brand direction from supplied logo

The supplied JPEG shows a plum Tebelopele wordmark, orange sunrise and golden rays on white. Use a clean white/off-white neutral canvas, plum for brand identity and primary navigation, orange/gold sparingly for action/highlight, and dark readable text. Extract precise colors from the original asset during Phase 1; test contrast before setting final tokens. Preserve the supplied logo as a source asset. A small-size favicon needs a simplified, approved sunrise mark because the complete wordmark will not remain legible at favicon sizes. Avoid clinical stock imagery and invented testimonials.
