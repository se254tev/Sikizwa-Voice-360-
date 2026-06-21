const aiService = require('../services/aiService');
const AuditLog = require('../models/AuditLog');

async function transcribe(req, res, next) {
  try {
    const transcript = await aiService.transcribe(req.file || req.body);
    await AuditLog.create({
      actor: req.user._id,
      actorAnonId: req.user.anonymousId,
      action: 'ai_transcribe',
      resource: 'AI',
      ip: req.ip,
      meta: { length: transcript.text?.length }
    });
    res.json(transcript);
  } catch (err) {
    next(err);
  }
}

async function emotionAnalysis(req, res, next) {
  try {
    const result = await aiService.emotionAnalysis(req.file || req.body);
    await AuditLog.create({
      actor: req.user._id,
      actorAnonId: req.user.anonymousId,
      action: 'ai_emotion_analysis',
      resource: 'AI',
      ip: req.ip
    });
    res.json(result);
  } catch (err) {
    next(err);
  }
}

async function riskScore(req, res, next) {
  try {
    const result = await aiService.riskScore(req.body);
    await AuditLog.create({
      actor: req.user._id,
      actorAnonId: req.user.anonymousId,
      action: 'ai_risk_score',
      resource: 'AI',
      ip: req.ip
    });
    res.json(result);
  } catch (err) {
    next(err);
  }
}

async function chat(req, res, next) {
  try {
    const reply = await aiService.chat(req.body);
    await AuditLog.create({
      actor: req.user._id,
      actorAnonId: req.user.anonymousId,
      action: 'ai_chat',
      resource: 'AI',
      ip: req.ip
    });
    res.json(reply);
  } catch (err) {
    next(err);
  }
}

module.exports = { transcribe, emotionAnalysis, riskScore, chat };