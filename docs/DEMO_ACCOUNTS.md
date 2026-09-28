# Demonstration accounts and access matrix

The provisioning script creates confirmed Supabase Auth accounts and writes their generated passwords to the ignored local file `.test-accounts.local.json`. Never commit that credential file. Rotate or remove every demonstration identity before production launch.

| Account | Role | Demonstrated access |
|---|---|---|
| `tebelopele.demo.admin@example.com` | System administrator | All platform capabilities, administration, configuration, staff, content, reports, audit and integrations |
| `tebelopele.demo.appointments@example.com` | Reception / appointment officer | Appointment schedule, operational appointment notes and notifications |
| `tebelopele.demo.navigator@example.com` | Support agent | Human takeover for general navigation and technical-support escalations |
| `tebelopele.demo.healthcontent@example.com` | Support agent | Human takeover for approved health-content guidance |
| `tebelopele.demo.referralsupport@example.com` | Support agent | Human takeover for referral-navigation conversations |
| `tebelopele.demo.referralofficer@example.com` | Referral officer | Referral register, status transitions and follow-up workflow |
| `tebelopele.demo.editor@example.com` | Content editor | Create and maintain governed content drafts and knowledge records |
| `tebelopele.demo.reviewer@example.com` | Content reviewer | Review, approve and publish content; monitor AI quality |
| `tebelopele.demo.reporting@example.com` | Reporting user | Scoped operational reporting and CSV export |
| `tebelopele.demo.auditor@example.com` | Auditor | Read audit trail and scoped operational reports |
| `tebelopele.demo.client1@example.com` | Client, shared-app demonstration | Own profile, consent, preferences, appointments, notifications and chat; also demonstrates application selection because it belongs to ePayment |
| `tebelopele.demo.client2@example.com` | Client | Own client portal and records only |
| `tebelopele.demo.client3@example.com` | Client | Own client portal and records only |

## Skill routing

Support cases can only be claimed by an available, accepting staff member whose verified skill matches the case requirement. The demonstration set covers `general_navigation`, `technical_support`, `appointment_support`, `content_guidance` and `referral_navigation`.

## Shared application identities

After successful authentication, membership is checked in the Tebelopele, ePayment and Bermuda Jobs profile tables. When more than one membership exists, `/choose-application` asks the user where to continue. External destinations require `TEBELOPELE_EPAYMENT_URL` and `TEBELOPELE_JOBS_URL` in the deployment environment.
