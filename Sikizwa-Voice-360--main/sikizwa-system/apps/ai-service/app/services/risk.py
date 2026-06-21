import asyncio
import os
import re
from transformers import pipeline

_risk_pipeline = None

KEYWORDS = [
    'suicide', 'kill myself', 'end my life', 'no reason to live',
    'hurt myself', 'die', 'worthless', 'hopeless', 'panic attack'
]

def get_risk_pipeline():
    global _risk_pipeline
    if _risk_pipeline is None:
        _risk_pipeline = pipeline('text-classification', model=os.getenv('RISK_MODEL', 'j-hartmann/emotion-english-distilroberta-base'))
    return _risk_pipeline


async def initialize_risk_pipeline():
    await asyncio.to_thread(get_risk_pipeline)


async def compute_risk_score(text):
    text_lower = text.lower()
    score = 0.0
    for keyword in KEYWORDS:
        if keyword in text_lower:
            score += 0.24
    classifier = await asyncio.to_thread(get_risk_pipeline)
    result = await asyncio.to_thread(classifier, text, truncation=True, top_k=2)
    categories = {item['label'].lower(): float(item['score']) for item in result}
    if categories.get('sadness', 0) > 0.7:
        score += 0.25
    if categories.get('fear', 0) > 0.7:
        score += 0.2
    score = min(score, 1.0)
    level = 'low'
    if score >= 0.8:
        level = 'emergency'
    elif score >= 0.5:
        level = 'high'
    elif score >= 0.25:
        level = 'medium'
    return {'score': score, 'level': level, 'emotion_tags': categories}
