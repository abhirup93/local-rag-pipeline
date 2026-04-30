# Tasks

> Tracks planned, in-progress, and completed work for the local-rag project.
> Update status as work progresses: `[ ]` → `[~]` (in progress) → `[x]` (done)

---

## Core Pipeline (`local_rag.ipynb`)

- [ ] Extract reusable functions from notebook into `rag/` Python module (chunking, embedding, retrieval, CDC)
- [ ] Add `main.py` CLI entry point wiring up the full pipeline (currently `main.py` is a stub)
- [ ] Parameterize chunk size (800) and overlap (120) via config/env instead of hardcoded constants
- [ ] Add retry logic + exponential backoff around Gemini embedding API calls
- [ ] Log CDC diff stats (chunks added/removed/unchanged) on each `cdc_update()` run

## Embeddings & Retrieval

- [ ] Benchmark `retrieve_context()` vs `retrieve_context_weighted()` — document which wins for this dataset
- [ ] Expose recency decay factor (λ) as a tunable parameter in `.env` / config
- [ ] Evaluate `gemini-embedding-001` vs Voyage AI on the same PDF corpus — compare top-k recall

## Vector Store

- [ ] Add ChromaDB collection metadata (model name, embed dim) so the store is self-describing
- [ ] Implement `purge_document()` to remove all chunks for a given PDF from ChromaDB + registries
- [ ] Write a health-check function that verifies ChromaDB chunk count matches `chunk_registry.json`

## Conversation Memory

- [ ] Cap `ConversationMemory` session history at N turns to prevent unbounded context growth
- [ ] Add `memory.export_markdown()` — human-readable conversation dump with sources
- [ ] Auto-load the latest `memory_checkpoints/*.json` on session start instead of starting fresh

## Alternative Backends

- [ ] Unify all backend notebooks (Voyage, Pinecone ×2, MongoDB, PostgreSQL, SQL Server) around a shared interface so backends are swappable
- [ ] Add CDC support to `voyage_embeddings.ipynb` (currently only `local_rag.ipynb` and `local_rag_sqlserver.ipynb` have it)
- [ ] Add CDC support to `local_rag_postgres.ipynb`
- [ ] Test MongoDB Atlas vector search on a fresh Atlas cluster and document required index config
- [ ] Benchmark ChromaDB vs pgvector vs SQL Server VECTOR on the same PDF corpus — latency and recall

## Observability & Quality

- [ ] Add per-query latency logging (embed time, retrieval time, LLM time)
- [ ] Create an eval harness: a small Q&A ground-truth set + automated answer scoring
- [ ] Add `.env.example` with all required keys (currently only documented in CLAUDE.md)

## Infrastructure

- [ ] Add `pytest` + at least one smoke test for `chunk_text()` and `cdc_update()` logic
- [ ] Configure `ruff` linter and add a pre-commit hook
- [ ] Add a GitHub Actions CI job that runs `uv sync` and the smoke tests on push
- [ ] Decide on and document a branching strategy (currently everything goes to `main`)

---

## Completed

- [x] Initial RAG pipeline with ChromaDB + Gemini embeddings (`local_rag.ipynb`)
- [x] CDC with SHA256 chunk diffing and `staleness_registry.json` / `chunk_registry.json`
- [x] Conversation memory with session checkpointing to `memory_checkpoints/`
- [x] Recency-weighted retrieval via exponential decay
- [x] Alternative backends: Voyage AI, Pinecone (×2), MongoDB Atlas
- [x] PostgreSQL pgvector backend (`local_rag_postgres.ipynb`) — pgvector HNSW indexing
- [x] SQL Server 2025 backend (`local_rag_sqlserver.ipynb`) — native `VECTOR(768)` type, DiskANN indexing, SQL-backed conversation memory
- [x] GitHub Actions: Claude Code Review + PR Assistant workflows
- [x] CLAUDE.md with full architecture documentation
- [x] README.md updated to cover all notebooks and API key requirements
- [x] Image embedding notebook (`voyage_image_embeddings.ipynb`) — `voyage-multimodal-3`, text→image retrieval, similarity matrix, image+caption fusion
