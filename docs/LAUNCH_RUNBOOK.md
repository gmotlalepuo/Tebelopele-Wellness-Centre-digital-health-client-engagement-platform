# Launch and rollback runbook

## Before launch

- Freeze the approved commit and record its Git SHA, Vercel deployment URL and Supabase migration version.
- Confirm production secrets exist only in managed environment storage and rotate any temporary Meta/AI tokens.
- Apply migrations using the approved owner-level process; capture success output and schema version.
- Execute the role/RLS test matrix for client, support agent, referral officer, reporting user, auditor and system administrator.
- Verify health, sign-in, appointment, chat escalation, human takeover, referral, report export and privacy routes.
- Confirm monitoring recipients and incident severity definitions.

## Launch

1. Promote the verified Vercel deployment.
2. Run read-only smoke tests against production.
3. Confirm webhook verification and observe provider events without resending or migrating the pending WhatsApp number.
4. Record the release time and accountable launch owner.

## Rollback

- Application: promote the previously verified Vercel deployment.
- Database: prefer a forward corrective migration. Do not reverse a migration that would discard operational records.
- Integration: disable the affected channel/endpoint through managed configuration and retain provider events for investigation.
- Escalate any confidentiality, integrity or availability incident using the agreed incident contacts.

## Post-launch

Review authentication failures, webhook failures, AI fallbacks, support queue age, referral follow-ups and error rates at the agreed cadence. Hold a launch review after the support window and record unresolved risks.
