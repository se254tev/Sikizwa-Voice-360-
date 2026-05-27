const axios = require('axios');
const FormData = require('form-data');
const http = require('http');
const https = require('https');
const { URL } = require('url');

const aiServiceUrl = process.env.AI_SERVICE_URL || 'http://ai:8000';
if (!process.env.AI_SERVICE_URL && process.env.NODE_ENV === 'production') {
  throw new Error('AI_SERVICE_URL must be configured in production');
}

const agentOptions = {
  keepAlive: true,
  maxSockets: 20,
  keepAliveMsecs: 60000
};
const agent = new URL(aiServiceUrl).protocol === 'https:'
  ? new https.Agent(agentOptions)
  : new http.Agent(agentOptions);

const aiClient = axios.create({
  baseURL: aiServiceUrl,
  timeout: 60000,
  httpAgent: agent,
  httpsAgent: agent,
  maxContentLength: Infinity,
  maxBodyLength: Infinity
});

const TIMEOUTS = {
  chat: 60000,
  transcribe: 90000,
  'emotion-analysis': 60000,
  'risk-score': 60000
};

function classifyError(error) {
  if (error.code === 'ECONNABORTED') {
    return 'timeout';
  }
  if (error.response) {
    return error.response.status >= 500 ? 'server_error' : 'client_error';
  }
  if (error.request) {
    return 'network_error';
  }
  return 'unknown';
}

function isRetryable(error) {
  if (error.code === 'ECONNABORTED') {
    return true;
  }
  if (!error.response) {
    return true;
  }
  return error.response.status >= 500;
}

async function sendAiRequest(path, payload, headers, operation) {
  const timeout = TIMEOUTS[operation] || 60000;
  const startTime = Date.now();
  const maxRetries = 1;
  let lastError;

  for (let attempt = 0; attempt <= maxRetries; attempt++) {
    const attemptStart = Date.now();
    try {
      const response = await aiClient.post(path, payload, {
        headers,
        timeout
      });
      console.info(JSON.stringify({
        event: 'ai_request_success',
        operation,
        path,
        attempt,
        durationMs: Date.now() - startTime,
        status: response.status
      }));
      return response.data;
    } catch (error) {
      lastError = error;
      console.error(JSON.stringify({
        event: 'ai_request_failure',
        operation,
        path,
        attempt,
        durationMs: Date.now() - attemptStart,
        errorType: classifyError(error),
        message: error.message,
        code: error.code,
        status: error.response?.status
      }));
      if (attempt < maxRetries && isRetryable(error)) {
        const backoff = 200 * 2 ** attempt;
        await new Promise((resolve) => setTimeout(resolve, backoff));
        continue;
      }
      throw error;
    }
  }

  throw lastError;
}

async function transcribe(file) {
  if (file && file.buffer) {
    const form = new FormData();
    form.append('file', file.buffer, { filename: file.originalname || 'audio.wav' });
    return sendAiRequest('/transcribe', form, form.getHeaders(), 'transcribe');
  }

  if (file && file.text) {
    return { text: file.text };
  }

  return { text: '' };
}

async function emotionAnalysis(file) {
  if (file && file.buffer) {
    const form = new FormData();
    form.append('file', file.buffer, { filename: file.originalname || 'audio.wav' });
    return sendAiRequest('/emotion-analysis', form, form.getHeaders(), 'emotion-analysis');
  }

  return sendAiRequest('/emotion-analysis', file, { 'Content-Type': 'application/json' }, 'emotion-analysis');
}

async function riskScore(payload) {
  return sendAiRequest('/risk-score', payload, { 'Content-Type': 'application/json' }, 'risk-score');
}

async function chat(payload) {
  return sendAiRequest('/chat', payload, { 'Content-Type': 'application/json' }, 'chat');
}

module.exports = { transcribe, emotionAnalysis, riskScore, chat };