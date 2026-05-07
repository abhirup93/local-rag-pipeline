# Local RAG Pipeline

A collection of local-first RAG (Retrieval-Augmented Generation) pipelines for PDF question-answering, exploring multiple vector database backends and embedding providers.

**Core stack:** PDF parsing (pypdf) · Gemini embeddings (gemini-embedding-001) · ChromaDB (local) · gpt-oss-20b via HuggingFace/Groq

## Features

- Sliding window chunking (800 chars, 120 char overlap)
- Asymmetric retrieval (`RETRIEVAL_DOCUMENT` / `RETRIEVAL_QUERY` modes)
- Conversation memory with disk checkpointing
- CDC (Change Data Capture) engine — SHA256 staleness tracking, only re-embeds changed chunks (~70% API savings)
- Recency-weighted retrieval via exponential decay on chunk ingestion time

## Notebooks

| Notebook | Embedding | Vector Store | Notes |
|---|---|---|---|
| `local_rag.ipynb` | Gemini `gemini-embedding-001` | ChromaDB (local) | Primary implementation — full CDC pipeline |
| `local_rag_postgres.ipynb` | Gemini | PostgreSQL pgvector | pgvector HNSW indexing, same CDC pipeline |
| `local_rag_sqlserver.ipynb` | Gemini | SQL Server 2025 `VECTOR(768)` | DiskANN cosine indexing, SQL-backed conversation memory |
| `voyage_embeddings.ipynb` | Voyage AI (`voyage-4-large`) | ChromaDB | Text embeddings with Voyage |
| `voyage_image_embeddings.ipynb` | Voyage AI (`voyage-multimodal-3`) | in-memory | Image embeddings, text→image retrieval, image+caption fusion |
| `voyage_image_clustering.ipynb` | Voyage AI (`voyage-multimodal-3`) | in-memory | PCA + K-Means clustering on image embeddings |
| `voyage_multimodal_pca_kmeans_caltech101_poc.ipynb` | Voyage AI | `voyage_caltech101_db_poc/` | Caltech-101 multimodal POC — PCA & K-Means |
| `voyage_multimodal_mongodb_pca_kmeans_poc.ipynb` | Voyage AI | MongoDB Atlas | Multimodal embeddings + PCA/K-Means stored in Atlas |
| `pinecone_vector_search_sample.ipynb` | sentence-transformers | Pinecone serverless | Basic Pinecone walkthrough |
| `pinecone_vector_search_voyage.ipynb` | Voyage AI | Pinecone serverless | Matryoshka dims, quantization options |
| `mongodb_voyage_embeddings.ipynb` | Voyage AI | MongoDB Atlas | HNSW vector search, similarity metric comparison |
| `event_driven_webhooks_using_gemini_api.ipynb` | Gemini | — | Event-driven webhook patterns with the Gemini API |

## Setup

Requires Python 3.11 and [`uv`](https://github.com/astral-sh/uv).

```bash
uv venv
.venv\Scripts\activate   # Windows

uv sync   # installs all dependencies declared in pyproject.toml
```

## Configuration

Create a `.env` file in the project root with the API keys for the backends you intend to use:

```env
# Required for primary notebook (Gemini embeddings)
GEMINI_API_KEY=...

# LLM inference via HuggingFace / Groq
HF_API_KEY=...

# OpenAI (if used as LLM backend)
OPENAI_API_KEY=...

# Anthropic Claude (if used as LLM backend)
CLAUDE_API_KEY=...

# PostgreSQL backend (local_rag_postgres.ipynb)
PG_PASSWORD=...   # defaults to "postgres" if unset

# Voyage AI notebooks
VOYAGEAI_API_KEY=...

# Pinecone notebooks
PINECONE_API_KEY=...

# MongoDB notebook
MONGODB_URI=...
ATLAS_MODEL_API_KEY=...
```

## Architecture (primary pipeline)

```
PDF → extract_text_from_pdf() → chunk_text() → embed_documents_batch()
    → store_in_chroma() → [user query] → retrieve_context() → generate_answer()
```

CDC-aware path uses `cdc_update()` + `store_in_chroma_v2()` to diff old vs new chunks and skip re-embedding unchanged content. State is tracked in `staleness_registry.json` (SHA256 hashes) and `chunk_registry.json` (chunk → ChromaDB UUID mapping).

## Runtime Artifacts

The following are generated at runtime and gitignored:

- `chroma_db/` — ChromaDB SQLite backend
- `memory_checkpoints/` — timestamped conversation session files
- `staleness_registry.json` / `chunk_registry.json` — CDC state
- `pdfs/versions/` — versioned PDFs used for CDC testing
- `voyage_caltech101_db_poc/raw_data/` & `selected_images/` — Caltech-101 images downloaded at runtime
- `sample_images/` — sample images re-fetched on demand
