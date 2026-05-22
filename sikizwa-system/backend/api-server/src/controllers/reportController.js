const Report = require('../models/Report');
const EmotionalAnalysis = require('../models/EmotionalAnalysis');
const AuditLog = require('../models/AuditLog');
const { scoreEmergency } = require('../services/riskService');

async function createReport(req, res, next) {
  try {
    const data = req.body;
    data.reporterUser = req.user?._id;
    data.reporterAnonId = req.user?.anonymousId;
    data.riskLevel = scoreEmergency(data);
    const report = await Report.create(data);
    await EmotionalAnalysis.create({ report: report._id, transcript: data.description, emotions: {}, riskScore: 0 });
    await AuditLog.create({
      actor: req.user?._id,
      actorAnonId: req.user?.anonymousId,
      action: 'create_report',
      resource: 'Report',
      resourceId: report._id,
      ip: req.ip,
      meta: { type: report.type, riskLevel: report.riskLevel }
    });
    res.status(201).json(report);
  } catch (err) {
    next(err);
  }
}

async function listReports(req, res, next) {
  try {
    const query = {};
    if (req.query.type) query.type = req.query.type;
    if (req.query.riskLevel) query.riskLevel = req.query.riskLevel;
    const reports = await Report.find(query).populate('emotionAnalysis').sort({ createdAt: -1 }).limit(100);
    res.json(reports);
  } catch (err) {
    next(err);
  }
}

module.exports = { createReport, listReports };
