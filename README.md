# Tebelopele digital health and client engagement platform

Planning and implementation workspace for Tebelopele Wellness Centre.

The agreed direction is a responsive Next.js application backed by Supabase Auth, PostgreSQL and Storage. A separate, Tebelopele supplied AI service will expose Qwen 2.5 through a server to server contract. Web chat and WhatsApp will share a conversation and human support model.

Start with [the implementation plan](docs/IMPLEMENTATION_PLAN.md), [architecture](docs/ARCHITECTURE.md), [data and permissions](docs/DATA_AND_ACCESS.md), [integration contracts](docs/INTEGRATION_CONTRACTS.md), and [open decisions](docs/DECISIONS.md). These are Phase 0 working artifacts, not evidence that services have been deployed or integrations connected.

Phase 1 application and database foundations are documented in [the Phase 1 guide](docs/PHASE_1_FOUNDATION.md). Use `npm ci`, configure `.env.local` from `.env.example`, and run `npm run dev`. Quality checks are `npm run lint`, `npm run typecheck`, `npm test` and `npm run build`.

Phase 2 public directories, health information, search, client profile/preferences and versioned consent are documented in [the Phase 2 guide](docs/PHASE_2_CLIENT_EXPERIENCE.md).

Phase 3 appointment and notification workflows are documented in [the Phase 3 guide](docs/PHASE_3_APPOINTMENTS_NOTIFICATIONS.md). Phase 4 content governance and knowledge retrieval are documented in [the Phase 4 guide](docs/PHASE_4_GOVERNED_KNOWLEDGE.md).

Source baselines: `TEBELOPELE_AI_Digital_Health_System_Requirements.md` and `Content Management, Knowledge Base, FAQ and Chatbot Handover`, supplied with the project brief. User decisions override illustrative options in those documents.
