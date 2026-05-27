import asyncio
import os
import librosa
import numpy as np
from transformers import pipeline
from app.utils.audio import save_upload_file

_emotion_pipeline = None

def get_emotion_pipeline():
    global _emotion_pipeline
    if _emotion_pipeline is None:
        _emotion_pipeline = pipeline('audio-classification', model=os.getenv('EMOTION_MODEL', 'superb/hubert-large-superb-er'))
    return _emotion_pipeline


async def initialize_emotion_pipeline():
    await asyncio.to_thread(get_emotion_pipeline)


async def analyze_emotion(file):
    path = await asyncio.to_thread(save_upload_file, file)
    try:
        signal, sr = await asyncio.to_thread(librosa.load, path, sr=16000)
        energy = np.mean(np.abs(signal))
        emotion_pipeline = await asyncio.to_thread(get_emotion_pipeline)
        labels = await asyncio.to_thread(emotion_pipeline, path, top_k=3)
        emotions = {item['label'].lower(): float(item['score']) for item in labels}
        urgency = 'low'
        if emotions.get('sadness', 0) > 0.6 or energy > 0.03:
            urgency = 'medium'
        if emotions.get('fear', 0) > 0.55 or emotions.get('anger', 0) > 0.5:
            urgency = 'high'
        if emotions.get('panic', 0) > 0.5:
            urgency = 'emergency'
        return emotions, urgency
    finally:
        if os.path.exists(path):
            os.remove(path)
