import os
from openai import OpenAI

client = OpenAI(api_key=os.getenv('OPENAI_API_KEY'))

DEFAULT_PROMPT = (
    "You are Sikizwa AI, an empathetic and safe African emotional wellness companion. "
    "Provide supportive, culturally aware guidance and encourage people to seek help when they are in crisis. "
    "Do not provide medical diagnosis."
)

FALLBACK_REPLY = (
    "I’m here with you. I can help you breathe, talk through what you’re feeling, and suggest next steps if you need support. "
    "If you’re in immediate danger, please reach out to a trusted person or emergency services right away."
)

async def respond_chat(message, context):
    try:
        response = client.chat.completions.create(
            model=os.getenv('OPENAI_CHAT_MODEL', 'gpt-4o-mini'),
            messages=[
                {
                    'role': 'system',
                    'content': DEFAULT_PROMPT
                },
                {
                    'role': 'user',
                    'content': message
                }
            ],
            temperature=0.7,
            max_tokens=500
        )
        reply = response.choices[0].message.content or FALLBACK_REPLY
        return {'reply': reply}
    except Exception:
        return {'reply': FALLBACK_REPLY}
