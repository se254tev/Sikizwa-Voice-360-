# Sikizwa AI Service

FastAPI microservice for voice transcription, emotion detection, risk assessment, and AI companion chat.

## Setup

1. Copy `.env.example` to `.env` and fill `OPENAI_API_KEY`.
   - Optionally configure `AI_CORS_ORIGINS` for allowed frontend origins.
2. Create a Python environment and install requirements:

```bash
cd apps/ai-service
python -m pip install -r requirements.txt
```

3. Run locally:

```bash
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

## Endpoints
- `GET /health`
- `POST /transcribe`
- `POST /emotion-analysis`
- `POST /risk-score`
- `POST /chat`
