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
| `pinecone_vector_search_sample.ipynb` | sentence-transformers | Pinecone serverless | Basic Pinecone walkthrough |
| `pinecone_vector_search_voyage.ipynb` | Voyage AI | Pinecone serverless | Matryoshka dims, quantization options |
| `mongodb_voyage_embeddings.ipynb` | Voyage AI | MongoDB Atlas | HNSW vector search, similarity metric comparison |

## Setup

Requires Python 3.11 and [`uv`](https://github.com/astral-sh/uv).

```bash
uv venv
.venv\Scripts\activate   # Windows

uv sync
uv add google-genai pypdf chromadb rich python-dotenv huggingface_hub fpdf2
```

## Configuration

Create a `.env` file in the project root with the API keys for the backends you intend to use:

```env
# Required for primary notebook
GEMINI_API_KEY=...
HF_API_KEY=...

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
