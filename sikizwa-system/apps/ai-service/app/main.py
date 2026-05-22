from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from app.services.transcribe import transcribe_audio
from app.services.emotion import analyze_emotion
from app.services.risk import compute_risk_score
from app.services.chat import respond_chat

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

@app.get('/health')
async def health():
    return {'status': 'ok'}

@app.post('/transcribe')
async def transcribe(file: UploadFile = File(...)):
    if not file.filename:
        raise HTTPException(status_code=400, detail='audio file required')
    text = await transcribe_audio(file)
    return {'text': text}

@app.post('/emotion-analysis')
async def emotion_analysis(file: UploadFile = File(...)):
    emotions, urgency = await analyze_emotion(file)
    return {'emotions': emotions, 'risk_level': urgency}

@app.post('/risk-score')
async def risk_score(payload: TextPayload):
    result = await compute_risk_score(payload.text)
    return result

@app.post('/chat')
async def chat(payload: ChatPayload):
    response = await respond_chat(payload.message, payload.context)
    return response
