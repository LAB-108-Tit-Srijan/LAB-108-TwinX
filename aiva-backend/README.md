# AIVA Backend

AI doubt solver for coding institutes — Node.js + TypeScript backend with RAG pipeline.

## Architecture

```
Video Upload → Whisper Transcription → Smart Chunking → OpenAI Embeddings → ChromaDB
                                                                                 ↓
Student Question → Question Embedding → Vector Search → RAG Context → Claude (SSE stream)
```

## Setup

### 1. Install dependencies

```bash
cd aiva-backend
npm install
```

### 2. Start ChromaDB

```bash
docker run -p 8001:8000 chromadb/chroma
```

### 3. Configure environment

Copy `.env` and fill in your API keys:

```bash
cp .env .env.local
```

| Variable | Description | Default |
|---|---|---|
| `PORT` | Server port | `8000` |
| `ANTHROPIC_API_KEY` | Claude API key | required |
| `OPENAI_API_KEY` | OpenAI key (Whisper + Embeddings) | required |
| `CHROMA_URL` | ChromaDB URL | `http://localhost:8001` |
| `MAX_FILE_SIZE_MB` | Max video upload size | `500` |
| `CHUNK_SIZE` | Target words per chunk | `300` |
| `CHUNK_OVERLAP` | Overlap words between chunks | `50` |

### 4. Run

```bash
# Development
npm run dev

# Production
npm run build && npm start
```

---

## API Reference

### Upload Video

```bash
curl -X POST http://localhost:8000/api/video/upload \
  -F "video=@lecture.mp4" \
  -F "title=React Hooks Deep Dive" \
  -F "instructor=Amit Kumar" \
  -F "course=React Mastery"
```

**Response:**
```json
{
  "success": true,
  "lecture_id": "550e8400-e29b-41d4-a716-446655440000",
  "message": "Video uploaded. Processing started.",
  "status": "transcribing"
}
```

---

### Check Processing Status

```bash
curl http://localhost:8000/api/video/{lecture_id}/status
```

**Response:**
```json
{
  "lecture_id": "550e8400-e29b-41d4-a716-446655440000",
  "status": "ready",
  "title": "React Hooks Deep Dive",
  "chunks_count": 47,
  "duration": 2551
}
```

Status values: `uploading` → `transcribing` → `processing` → `ready` | `failed`

---

### Ask a Question (SSE Stream)

```bash
curl -X POST http://localhost:8000/api/ask \
  -H "Content-Type: application/json" \
  -d '{
    "lecture_id": "550e8400-e29b-41d4-a716-446655440000",
    "question": "useEffect mein dependency array kyun use kiya?",
    "language": "hi",
    "chat_history": []
  }'
```

**SSE Events:**
```
data: {"type":"delta","text":"useEffect mein dependency..."}
data: {"type":"delta","text":" array isliye use kiya..."}
data: {"type":"done","timestamps":["12:30","15:42"],"source_chunks":[...]}
```

**Request body:**

| Field | Type | Required | Description |
|---|---|---|---|
| `lecture_id` | string | yes | UUID from upload |
| `question` | string | yes | Student's question |
| `language` | `en` \| `hi` | no | Response language (default: `en`) |
| `chat_history` | array | no | Previous messages |
| `current_timestamp` | number | no | Current video position (seconds) |

---

### List All Lectures

```bash
curl http://localhost:8000/api/lectures
```

---

### Get Lecture Details

```bash
curl http://localhost:8000/api/lectures/{id}
```

---

### Delete Lecture

```bash
curl -X DELETE http://localhost:8000/api/lectures/{id}
```

Removes the lecture, its video file, and its ChromaDB collection.

---

### Health Check

```bash
curl http://localhost:8000/health
```

---

## Data Persistence

Lecture metadata is stored in `lectures.json` (auto-created in the project root). Vector embeddings live in ChromaDB. No database required.

## Notes

- Video processing is **non-blocking** — upload returns immediately, transcription + embedding runs in background
- Responses are streamed via **Server-Sent Events (SSE)**
- Supports **Hindi (Hinglish)** and **English** responses
- Smart chunking respects sentence boundaries and adds overlap for context continuity
