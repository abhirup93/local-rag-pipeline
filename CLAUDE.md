# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Setup & Commands

This project uses `uv` for dependency management. Python 3.11 is required.

```bash
# Create and activate virtual environment
uv venv
.venv\Scripts\activate  # Windows

# Install dependencies
uv sync

# Install additional extras
uv add google-genai pypdf chromadb rich python-dotenv huggingface_hub fpdf2
```

There is no build step, test suite, or linter configured. The project is primarily Jupyter notebook-based — run notebooks sequentially in Jupyter Lab/Notebook.

## Architecture

This is a local-first RAG (Retrieval-Augmented Generation) pipeline for PDF question-answering. The main implementation lives in `local_rag.ipynb`.

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

### Alternative Backends (separate notebooks)

| Notebook | Embedding | Vector Store |
|---|---|---|
| `voyage_embeddings.ipynb` | Voyage AI (1024-dim) | ChromaDB |
| `pinecone_vector_search_sample.ipynb` | Gemini | Pinecone |
| `pinecone_vector_search_voyage.ipynb` | Voyage AI | Pinecone |
| `mongodb_voyage_embeddings.ipynb` | Voyage AI | MongoDB Atlas |

### Required API Keys (in `.env`)

- `GEMINI_API_KEY` — embeddings (primary)
- `HF_API_KEY` — LLM inference via HuggingFace/Groq
- `VOYAGEAI_API_KEY` — Voyage AI notebooks
- `PINECONE_API_KEY` — Pinecone notebooks
- `MONGODB_URI` + `ATLAS_MODEL_API_KEY` — MongoDB notebook

`.env` is gitignored. `chroma_db/`, `memory_checkpoints/`, and both registry JSON files are also gitignored — they are runtime artifacts.
