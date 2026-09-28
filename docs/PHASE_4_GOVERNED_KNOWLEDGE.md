# Phase 4 — Governed health content and knowledge

## Delivered

- Staff content register, controlled draft authoring, exact-version review history and publication RPC.
- Existing public article and FAQ records extended instead of duplicated.
- Immutable versions with source object, filename, MIME type, byte size and SHA-256 lineage.
- Private `tebelopele-knowledge` bucket with a 10 MB allow-list.
- Durable extraction, chunking, embedding, reindex and removal job records.
- Version-linked chunks, full-text indexing and published/effective/non-expired retrieval.
- A retrieval console showing article, URL and exact-version citations.

Only a processing-ready version with a recorded approval may be published. Retrieval joins chunks to the exact `published_version_id`; drafts, restricted records and expired content are excluded.

PDF/DOCX extraction and embeddings belong to an external worker. The schema stores provider/model lineage and provider-neutral embedding payloads until the supplied endpoint defines a fixed dimension. Keyword retrieval is implemented; semantic ranking remains explicitly pending that contract.

Deployment acceptance is upload → approval → publication → index → cited retrieval, plus negative tests proving that clients and anonymous users cannot read drafts, sources, reviews or staff notes.
