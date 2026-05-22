import os
from openai import OpenAI

client = OpenAI(api_key=os.getenv('OPENAI_API_KEY'))

DEFAULT_PROMPT = (
    "You are Sikizwa AI, an empathetic and safe African emotional wellness companion. "
    "Provide supportive, culturally aware guidance and encourage people to seek help when they are in crisis. "
    "Do not provide medical diagnosis."
)

async def respond_chat(message, context):
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
    reply = response.choices[0].message.content or 'I am here with you. Can you tell me more?'
    return {'reply': reply}
