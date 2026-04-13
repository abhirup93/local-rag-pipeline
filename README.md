# Local RAG Pipeline

Production-grade local RAG pipeline — 100% free stack.

**Stack:** PDF parsing (pypdf) · Gemini embeddings (gemini-embedding-001) · ChromaDB (local) · gpt-oss-20b via HuggingFace + Groq

**Features:**
- Sliding window chunking with overlap
- Asymmetric retrieval (RETRIEVAL_DOCUMENT / RETRIEVAL_QUERY)
- Conversation memory with disk checkpointing
- Staleness tracking via SHA256 file hashing
- CDC engine — only re-embeds changed chunks (up to 70% API savings)
- Recency-weighted retrieval via exponential decay

**Full walkthrough:** [Medium article link]

## Setup

```cmd
uv venv
.venv\Scripts\activate
uv add google-genai pypdf chromadb rich python-dotenv huggingface_hub fpdf2
```

Add `.env` with `GEMINI_API_KEY` and `HF_API_KEY`, then open `local_rag.ipynb`.