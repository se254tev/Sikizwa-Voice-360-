import asyncio
import os
from openai import OpenAI
from app.utils.audio import save_upload_file

client = OpenAI(api_key=os.getenv('OPENAI_API_KEY'))


def _sync_transcribe(temp_path):
    with open(temp_path, 'rb') as audio_file:
        response = client.audio.transcriptions.create(
            file=audio_file,
            model=os.getenv('WHISPER_MODEL', 'whisper-1'),
            language=os.getenv('DEFAULT_LANGUAGE', 'en')
        )
    return response.text


async def transcribe_audio(file):
    temp_path = await asyncio.to_thread(save_upload_file, file)
    try:
        return await asyncio.to_thread(_sync_transcribe, temp_path)
    finally:
        if os.path.exists(temp_path):
            os.remove(temp_path)
