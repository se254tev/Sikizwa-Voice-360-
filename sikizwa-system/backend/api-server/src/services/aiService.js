const axios = require('axios');
const FormData = require('form-data');

const aiClient = axios.create({
  baseURL: process.env.AI_SERVICE_URL || 'http://localhost:8000',
  timeout: 20000
});

async function transcribe(file){
  if (file && file.buffer) {
    const form = new FormData();
    form.append('file', file.buffer, { filename: file.originalname || 'audio.wav' });
    const res = await aiClient.post('/transcribe', form, { headers: form.getHeaders() });
    return res.data;
  }
  if (file && file.text) {
    return { text: file.text };
  }
  return { text: '' };
}

async function emotionAnalysis(file){
  if (file && file.buffer) {
    const form = new FormData();
    form.append('file', file.buffer, { filename: file.originalname || 'audio.wav' });
    const res = await aiClient.post('/emotion-analysis', form, { headers: form.getHeaders() });
    return res.data;
  }
  const res = await aiClient.post('/emotion-analysis', file);
  return res.data;
}

async function riskScore(payload){
  const res = await aiClient.post('/risk-score', payload);
  return res.data;
}

async function chat(payload){
  const res = await aiClient.post('/chat', payload);
  return res.data;
}

module.exports = { transcribe, emotionAnalysis, riskScore, chat };