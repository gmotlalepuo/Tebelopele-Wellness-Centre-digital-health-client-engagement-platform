# Data model and access plan

All application-owned public-schema tables use the approved `tebelopele_` prefix. Supabase-managed tables such as `auth.users` retain their platform names and are not duplicated. Database functions, storage policies and migrations should follow the same Tebelopele naming convention where applicable.

| Domain | Main logical entities | Relationship and rule |
| --- | --- | --- |
| Identity | profiles, roles, capabilities, user_roles, staff_profiles, staff_skills, staff_facilities, availability | Profile links to `auth.users`; staff skill has proficiency and verified/active state; assignment only to eligible active staff. |
| Client and consent | clients, contacts, preferences, consent_versions, client_consents | Client ownership and facility scope are explicit; consent event records version/channel/time and withdrawal. |
| Directory | facilities, facility_hours, services, facility_services, outreach | Only published public records are anonymous-readable; staff writes require capability. |
| Appointments | slots, appointments, status_events, notes | Slot allocation is atomic; private notes are staff-scoped; external scheduling IDs are unique where used. |
| Knowledge | categories, articles, article_versions, FAQs, FAQ_versions, reviews, storage_objects, chunks, index_jobs | Published version pointer is separate from newest draft; citation stores exact version/chunk. |
| Conversation | conversations, messages, message_feedback, support_cases, support_events, internal_notes | One transcript spans AI, menu and human; internal notes are excluded from client and AI views. |
| WhatsApp | channel_identities, flow_versions, flow_states, provider_events, message_deliveries | Provider message/event IDs are unique for idempotency; identity verification status gates private actions. |
| Referral/operations | referrals, referral_events, notifications, notification_attempts, audit_events, integration_events | Role/facility scope applies; logs store safe metadata rather than clinical message bodies. |

## Permission baseline

| Actor | Own profile/appointments | Published content | Draft/review content | Transcript/case | Staff/admin operations |
| --- | --- | --- | --- | --- | --- |
| Anonymous | None | Public only | None | None | None |
| Client | Own only | Public and approved client content | None | Own public messages/status | None |
| Reception | Assigned facility and authorized appointment fields | Approved | None | Assigned case only if permitted | Booking/availability capability |
| Support/health worker | Authorized client context only | Approved | Optional editor capability | Assigned or explicitly accepted case; private notes | Skill/facility-scoped case actions |
| Editor/reviewer | Own profile | Approved | Capability-based; reviewer approval recorded per version | None unless separately assigned | Content workflow only |
| Administrator | Role-scoped, audited operational access | Approved | Capability-based | No blanket private transcript access; explicit case/audit capability | Account, configuration and operations |
| Auditor | Read-only approved audit scope | As permitted | Review history only | Restricted access under approved policy | Audit/report scope only |

Every table containing user, client, facility, conversation or content visibility must have RLS policies and a negative cross-user test. Capability checks must come from trusted database state, not browser-provided role names. Audit privileged reads where policy requires. The exact clinical and facility access matrix is a Phase 0 sign-off item.
