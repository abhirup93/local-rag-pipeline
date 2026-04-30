# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Setup & Commands

This project uses `uv` for dependency management. Python 3.11 is required.

```bash
# Create and activate virtual environment
uv venv
.venv\Scripts\activate  # Windows

# Install all dependencies (defined in pyproject.toml)
uv sync
```

All dependencies (`chromadb`, `google-genai`, `pypdf`, `pgvector`, `psycopg2-binary`, `pyodbc`, `pymongo`, `pinecone`, `voyageai`, `sentence-transformers`, `huggingface-hub`, `rich`, `python-dotenv`, `fpdf2`, `ipywidgets`) are declared in `pyproject.toml` and installed by `uv sync`.

There is no build step, test suite, or linter configured. The project is primarily Jupyter notebook-based — run notebooks sequentially in Jupyter Lab/Notebook.

## Architecture

This is a local-first RAG (Retrieval-Augmented Generation) pipeline for PDF question-answering. The primary implementation lives in `local_rag.ipynb`; alternative backend notebooks share the same core pipeline.

### Pipeline Flow

```
PDF → extract_text_from_pdf() → chunk_text() → embed_documents_batch()
    → store_in_chroma() → [user query] → retrieve_context() → generate_answer()
```

### Key Subsystems

**Chunking:** Sliding window, 800 chars/chunk, 120 char overlap. Implemented in `chunk_text()`.

**Embeddings:** Gemini `gemini-embedding-001` (768-dim) via `google-genai`. Batched at 50 chunks/call with 0.3s pause. Asymmetric retrieval — documents and queries use different embed modes.

**Vector Store:** ChromaDB running locally (SQLite backend at `chroma_db/`). Collection accessed via `get_collection()`.

**CDC (Change Data Capture):** Two JSON registries track document state:
- `staleness_registry.json` — SHA256 file hashes + version counters per PDF
- `chunk_registry.json` — maps chunk content hashes to ChromaDB UUIDs

`cdc_update()` diffs old vs new chunks and only re-embeds changed ones (~70% API savings). `store_in_chroma_v2()` is the CDC-aware storage path.

**Conversation Memory:** `ConversationMemory` class maintains session history with source attribution. Sessions persist to `memory_checkpoints/*.json` (timestamped). `ask()` uses standard retrieval; `ask_weighted()` adds recency decay.

**Recency Weighting:** `recency_decay()` applies exponential decay to similarity scores based on chunk ingestion time. Controlled by `retrieve_context_weighted()`.

### All Notebooks

| Notebook | Embedding | Vector Store | Notes |
|---|---|---|---|
| `local_rag.ipynb` | Gemini `gemini-embedding-001` | ChromaDB (local) | Primary — full CDC pipeline |
| `local_rag_postgres.ipynb` | Gemini | PostgreSQL pgvector | pgvector HNSW indexing; requires local PostgreSQL |
| `local_rag_sqlserver.ipynb` | Gemini | SQL Server 2025 `VECTOR(768)` | DiskANN cosine indexing, SQL-backed conversation memory; requires SQL Server 2025 |
| `voyage_embeddings.ipynb` | Voyage AI `voyage-4-large` (1024-dim) | ChromaDB | Text embeddings with Voyage |
| `voyage_image_embeddings.ipynb` | Voyage AI `voyage-multimodal-3` (1024-dim) | in-memory | Image embeddings, text→image retrieval, image+caption fusion |
| `pinecone_vector_search_sample.ipynb` | sentence-transformers | Pinecone serverless | Basic Pinecone walkthrough |
| `pinecone_vector_search_voyage.ipynb` | Voyage AI | Pinecone serverless | Matryoshka dims, quantization options |
| `mongodb_voyage_embeddings.ipynb` | Voyage AI | MongoDB Atlas | HNSW vector search, similarity metric comparison |

### Required API Keys (in `.env`)

- `GEMINI_API_KEY` — embeddings (all notebooks except Voyage/Pinecone-only)
- `HF_API_KEY` — LLM inference via HuggingFace/Groq (all notebooks)
- `PG_PASSWORD` — PostgreSQL password (`local_rag_postgres.ipynb`; defaults to `"postgres"`)
- `VOYAGEAI_API_KEY` — Voyage AI notebooks
- `PINECONE_API_KEY` — Pinecone notebooks
- `MONGODB_URI` + `ATLAS_MODEL_API_KEY` — MongoDB notebook

SQL Server notebook uses Windows Authentication via ODBC — no password env var needed. Update `SQL_SERVER` in the notebook to match your SSMS server name.

### Runtime Artifacts (gitignored)

- `chroma_db/` — ChromaDB SQLite backend
- `memory_checkpoints/` — timestamped conversation session JSON files
- `staleness_registry.json` / `chunk_registry.json` — CDC state
- `pdfs/versions/` — versioned PDFs used for CDC testing
