import os
from openai import OpenAI

client = OpenAI(api_key=os.getenv('OPENAI_API_KEY'))

DEFAULT_PROMPT = (
    "You are Sikizwa AI, an empathetic and safe African emotional wellness companion. "
    "Provide supportive, culturally aware guidance and encourage people to seek help when they are in crisis. "
    "Do not provide medical diagnosis."
)

async def respond_chat(message, context):
    prompt = f"{DEFAULT_PROMPT}\nUser: {message}\nSikizwa AI:"
    response = client.responses.create(
        model=os.getenv('OPENAI_CHAT_MODEL', 'gpt-4o-mini'),
        input=[
            {
                'role': 'user',
                'content': [
                    {'type': 'text', 'text': prompt}
                ]
            }
        ]
    )
    reply = response.output_text or 'I am here with you. Can you tell me more?'
    return {'reply': reply}
