# Phase 3 — Appointments and notifications

## Delivered

- Client appointment list, available-slot selection, atomic booking, rescheduling and cancellation.
- Staff schedule protected by `appointments.manage`; restricted notes use `appointments.notes`.
- Capacity locking, overlap prevention, facility/service validation and append-only status history.
- Notification templates, idempotent queued deliveries, attempt history, retry state and a client notification centre.
- Audit events for appointment mutations.

Database RPCs are the supported mutation boundary. A delivery worker may claim due notifications, call a configured email/SMS/WhatsApp adapter, append an attempt and update state. Provider secrets remain server-side. An external scheduling adapter must preserve RPC invariants and map its reference to `external_reference`.

Apply the migration to the intended Supabase project, assign capabilities, and verify collision handling, staff scope, retries and audit records there. Local build checks do not constitute deployment or provider-delivery proof.
