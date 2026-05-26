import logging
import os

from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from app.services.transcribe import transcribe_audio
from app.services.emotion import analyze_emotion
from app.services.risk import compute_risk_score
from app.services.chat import respond_chat

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger('sikizwa-ai-service')

app = FastAPI(
    title='Sikizwa AI Service',
    description='AI microservice for transcription, emotion detection, distress scoring, and AI companion responses.',
    version='0.2.0'
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=['*'],
    allow_credentials=True,
    allow_methods=['*'],
    allow_headers=['*'],
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


@app.on_event('startup')
def startup_event():
    port = os.getenv('PORT', '8000')
    missing = environment_validation_status()
    logger.info('Sikizwa AI Service starting')
    logger.info('PORT=%s', port)
    if missing:
        logger.warning('Environment validation status: missing %s', ', '.join(missing))
    else:
        logger.info('Environment validation status: ok')


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
        text = await transcribe_audio(file)
        return {'text': text}
    except Exception:
        raise HTTPException(status_code=500, detail='transcribe failed')


@app.post('/emotion-analysis')
async def emotion_analysis(file: UploadFile = File(...)):
    try:
        emotions, urgency = await analyze_emotion(file)
        return {'emotions': emotions, 'risk_level': urgency}
    except Exception:
        raise HTTPException(status_code=500, detail='emotion analysis failed')


@app.post('/risk-score')
async def risk_score(payload: TextPayload):
    try:
        result = await compute_risk_score(payload.text)
        return result
    except Exception:
        raise HTTPException(status_code=500, detail='risk score failed')


@app.post('/chat')
async def chat(payload: ChatPayload):
    try:
        response = await respond_chat(payload.message, payload.context)
        return response
    except Exception:
        raise HTTPException(status_code=500, detail='chat request failed')
