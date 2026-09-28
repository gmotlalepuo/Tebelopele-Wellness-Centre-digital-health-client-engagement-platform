# Backup, restore and incident rehearsal

## Restore rehearsal

1. Record Supabase backup time, source project and restore operator.
2. Restore into an isolated non-production project; never overwrite production for a rehearsal.
3. Apply any later migrations in order.
4. Compare row counts for profiles, appointments, conversations/messages, support cases, referrals/events and audit events.
5. Run integrity checks for orphaned references and verify representative role access.
6. Record recovery point, elapsed recovery time, exceptions and approving owner.
7. Destroy rehearsal access and credentials according to the retention policy.

## Incident path

- Contain: disable the affected integration or deployment without deleting evidence.
- Assess: identify affected records, users, time range and exposure.
- Preserve: retain audit/provider events and correlation identifiers.
- Recover: use a verified deployment or isolated restore; prefer forward database repair.
- Communicate: follow the approved privacy, clinical-safety and service-owner notification paths.
- Learn: document cause, response times, corrective actions and owners.

Actual restoration success and incident contacts must be evidenced and signed off; this runbook does not claim that rehearsal has occurred.
