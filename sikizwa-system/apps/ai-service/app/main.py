import asyncio
import json
import logging
import os
from time import perf_counter

from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from app.services.transcribe import transcribe_audio
from app.services.emotion import analyze_emotion, initialize_emotion_pipeline
from app.services.risk import compute_risk_score, initialize_risk_pipeline
from app.services.chat import respond_chat

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger('sikizwa-ai-service')

app = FastAPI(
    title='Sikizwa AI Service',
    description='AI microservice for transcription, emotion detection, distress scoring, and AI companion responses.',
    version='0.2.0'
)

def parse_cors_origins():
    default_origins = [
        'https://sikizwa.com',
        'https://app.sikizwa.com',
        'http://localhost:3000',
    ]
    raw_origins = os.getenv('AI_CORS_ORIGINS', '').strip()
    if raw_origins:
        origins = [origin.strip() for origin in raw_origins.split(',') if origin.strip()]
        return origins if origins else default_origins
    return default_origins

app.add_middleware(
    CORSMiddleware,
    allow_origins=parse_cors_origins(),
    allow_credentials=True,
    allow_methods=['GET', 'POST', 'OPTIONS'],
    allow_headers=['Authorization', 'Content-Type', 'X-Requested-With', 'Accept'],
)

class TextPayload(BaseModel):
    text: str

class ChatPayload(BaseModel):
    message: str
    context: dict = {}


def environment_validation_status():
    missing = []
    if not os.getenv('OPENAI_API_KEY'):
        missing.append('OPENAI_API_KEY')
    if not os.getenv('WHISPER_MODEL'):
        missing.append('WHISPER_MODEL')
    return missing


async def warmup_models():
    start = perf_counter()
    await asyncio.gather(
        initialize_emotion_pipeline(),
        initialize_risk_pipeline()
    )
    duration = int((perf_counter() - start) * 1000)
    logger.info(json.dumps({
        'event': 'model_warmup_complete',
        'duration_ms': duration
    }))


@app.on_event('startup')
async def startup_event():
    port = os.getenv('PORT', '8000')
    missing = environment_validation_status()
    logger.info(json.dumps({
        'event': 'startup',
        'port': port,
        'environment_status': 'missing' if missing else 'ok',
        'missing': missing
    }))
    await warmup_models()


async def log_operation(operation: str, payload):
    start = perf_counter()
    try:
        return await payload
    finally:
        duration_ms = int((perf_counter() - start) * 1000)
        logger.info(json.dumps({
            'event': 'ai_request',
            'operation': operation,
            'duration_ms': duration_ms
        }))


@app.get('/')
async def root():
    return {
        'status': 'ok',
        'service': 'Sikizwa AI Service'
    }


@app.get('/health')
async def health():
    return {'status': 'healthy'}


@app.post('/transcribe')
async def transcribe(file: UploadFile = File(...)):
    if not file.filename:
        raise HTTPException(status_code=400, detail='audio file required')
    try:
        text = await log_operation('transcribe', transcribe_audio(file))
        return {'text': text}
    except Exception as exc:
        logger.exception('transcribe failed')
        raise HTTPException(status_code=500, detail='transcribe failed') from exc


@app.post('/emotion-analysis')
async def emotion_analysis(file: UploadFile = File(...)):
    try:
        emotions, urgency = await log_operation('emotion_analysis', analyze_emotion(file))
        return {'emotions': emotions, 'risk_level': urgency}
    except Exception as exc:
        logger.exception('emotion analysis failed')
        raise HTTPException(status_code=500, detail='emotion analysis failed') from exc


@app.post('/risk-score')
async def risk_score(payload: TextPayload):
    try:
        result = await log_operation('risk_score', compute_risk_score(payload.text))
        return result
    except Exception as exc:
        logger.exception('risk score failed')
        raise HTTPException(status_code=500, detail='risk score failed') from exc


@app.post('/chat')
async def chat(payload: ChatPayload):
    try:
        response = await log_operation('chat', respond_chat(payload.message, payload.context))
        return response
    except Exception as exc:
        logger.exception('chat request failed')
        raise HTTPException(status_code=500, detail='chat request failed') from exc
