const Report = require('../models/Report');
const EmotionalAnalysis = require('../models/EmotionalAnalysis');
const AuditLog = require('../models/AuditLog');
const { scoreEmergency } = require('../services/riskService');
const { getPrivacySettings } = require('../utils/settings');
const { serializeReport, formatTitle, inferMoodStatus } = require('../utils/reportSerializer');

function buildReportPayload(req) {
  const privacy = getPrivacySettings(req.user);
  const description = typeof req.body.description === 'string' ? req.body.description.trim() : '';
  const riskLevel = scoreEmergency(req.body);

  const payload = {
    ...req.body,
    description,
    riskLevel,
    title: req.body.title || formatTitle(req.body.type),
    emotional_summary: req.body.emotional_summary || description,
    mood_status: req.body.mood_status || inferMoodStatus(riskLevel),
    status: req.body.status || 'open',
  };

  if (privacy.profile_visibility === 'anonymous') {
    payload.reporterUser = undefined;
  } else if (req.user?._id) {
    payload.reporterUser = req.user._id;
  }

  payload.reporterAnonId = req.user?.anonymousId || payload.reporterAnonId;
  return payload;
}

async function createReport(req, res, next) {
  try {
    const payload = buildReportPayload(req);
    const report = await Report.create(payload);
    await EmotionalAnalysis.create({ report: report._id, transcript: payload.description, emotions: {}, riskScore: 0 });
    await AuditLog.create({
      actor: req.user?._id,
      actorAnonId: req.user?.anonymousId,
      action: 'create_report',
      resource: 'Report',
      resourceId: report._id,
      ip: req.ip,
      meta: { type: report.type, riskLevel: report.riskLevel }
    });
    res.status(201).json(serializeReport(report));
  } catch (err) {
    next(err);
  }
}

async function listReports(req, res, next) {
  try {
    const query = {};
    const privacy = getPrivacySettings(req.user);

    if (req.query.type) query.type = req.query.type;
    if (req.query.riskLevel) query.riskLevel = req.query.riskLevel;

    if (privacy.profile_visibility === 'anonymous' && req.user?.anonymousId) {
      query.reporterAnonId = req.user.anonymousId;
    } else {
      query.$or = [
        { reporterUser: req.user._id },
        { reporterAnonId: req.user?.anonymousId },
      ];
    }

    const reports = await Report.find(query).populate('emotionAnalysis').sort({ createdAt: -1 }).limit(100);
    res.json(reports.map((report) => serializeReport(report)));
  } catch (err) {
    next(err);
  }
}

module.exports = { createReport, listReports };
