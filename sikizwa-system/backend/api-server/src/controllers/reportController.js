const Report = require('../models/Report');
const EmotionalAnalysis = require('../models/EmotionalAnalysis');
const AuditLog = require('../models/AuditLog');
const User = require('../models/User');
const logger = require('../config/logger');
const { scoreEmergency } = require('../services/riskService');
const { getPrivacySettings } = require('../utils/settings');
const { sendNotification } = require('../services/notificationService');
const { serializeReport, formatTitle, inferMoodStatus } = require('../utils/reportSerializer');

function normalizeBoolean(value) {
  if (typeof value === 'boolean') {
    return value;
  }

  if (typeof value === 'string') {
    return ['true', 'yes', '1', 'on'].includes(value.trim().toLowerCase());
  }

  return false;
}

function normalizeReportType(value) {
  const normalized = typeof value === 'string' ? value.trim().toLowerCase() : '';
  if (['problem', 'support', 'check_in', 'complaint', 'emergency'].includes(normalized)) {
    return normalized;
  }

  return 'problem';
}

function normalizeIncidentType(value, fallback = 'Support update') {
  const normalized = typeof value === 'string' ? value.trim() : '';
  return normalized.length > 0 ? normalized : fallback;
}

function normalizeLocation(value) {
  if (typeof value === 'string') {
    return value.trim();
  }

  if (value && typeof value === 'object') {
    if (typeof value.address === 'string' && value.address.trim().length > 0) {
      return value.address.trim();
    }

    if (Array.isArray(value.coordinates) && value.coordinates.length === 2) {
      return `Lat ${value.coordinates[0]}, Lng ${value.coordinates[1]}`;
    }
  }

  return '';
}

function normalizePriority(value) {
  const normalized = typeof value === 'string' ? value.trim().toLowerCase() : '';
  if (['low', 'medium', 'high'].includes(normalized)) {
    return normalized;
  }

  return 'medium';
}

function normalizeStatus(value) {
  const normalized = typeof value === 'string' ? value.trim().toLowerCase() : '';
  if (['pending', 'open', 'in-progress', 'resolved', 'closed', 'escalated'].includes(normalized)) {
    return normalized;
  }

  return 'pending';
}

function normalizeTimestamp(value) {
  if (!value) {
    return new Date();
  }

  const parsed = new Date(value);
  if (Number.isNaN(parsed.getTime())) {
    return new Date();
  }

  return parsed;
}

function buildReportPayload(req) {
  const privacy = getPrivacySettings(req.user);
  const description = typeof req.body.description === 'string' ? req.body.description.trim() : '';
  const anonymousSubmission = normalizeBoolean(req.body.anonymousSubmission);
  const incidentType = normalizeIncidentType(req.body.incidentType || req.body.type, 'Support update');
  const location = normalizeLocation(req.body.location);
  const reportType = normalizeReportType(req.body.reportType);
  const timestamp = normalizeTimestamp(req.body.timestamp);
  const priority = normalizePriority(req.body.priority);
  const status = normalizeStatus(req.body.status);
  const riskLevel = scoreEmergency({
    ...req.body,
    notes: description,
    location,
  });

  const payload = {
    ...req.body,
    type: req.body.type || 'support',
    reportType,
    incidentType,
    title: req.body.title || incidentType,
    description,
    location,
    anonymousSubmission,
    priority,
    timestamp,
    riskLevel,
    emotional_summary: req.body.emotional_summary || description,
    mood_status: req.body.mood_status || inferMoodStatus(riskLevel),
    status,
  };

  if (anonymousSubmission) {
    payload.reporterUser = undefined;
    payload.reporterAnonId = req.user?.anonymousId || (req.user?._id ? String(req.user._id) : undefined);
  } else if (privacy.profile_visibility === 'anonymous') {
    payload.reporterUser = undefined;
    payload.reporterAnonId = req.user?.anonymousId || (req.user?._id ? String(req.user._id) : undefined);
  } else if (req.user?._id) {
    payload.reporterUser = req.user._id;
    payload.reporterAnonId = req.user?.anonymousId || undefined;
  }

  return payload;
}

async function notifyAdminsOfReport(report) {
  const admins = await User.find({ role: { $in: ['admin', 'super_admin'] } }).select('_id');
  await Promise.all(
    admins.map((admin) =>
      sendNotification(admin._id, {
        type: 'report_submitted',
        title: 'New report submitted',
        body: `A new ${report.incidentType || 'support'} report is waiting for review.`,
        data: {
          reportId: String(report._id),
          reportType: report.reportType || 'problem',
          status: report.status,
        },
      })
    )
  );
}

async function createReport(req, res, next) {
  try {
    const payload = buildReportPayload(req);
    const report = await Report.create(payload);

    void EmotionalAnalysis.create({
      report: report._id,
      transcript: payload.description,
      emotions: {},
      riskScore: 0,
    }).catch((error) => {
      logger.error('Failed to create emotional analysis for report', {
        reportId: String(report._id),
        error: error.message,
      });
    });

    void AuditLog.create({
      actor: req.user?._id,
      actorAnonId: req.user?.anonymousId,
      action: 'create_report',
      resource: 'Report',
      resourceId: report._id,
      ip: req.ip,
      meta: { type: report.type, riskLevel: report.riskLevel },
    }).catch((error) => {
      logger.error('Failed to create audit log for report', {
        reportId: String(report._id),
        error: error.message,
      });
    });

    void notifyAdminsOfReport(report).catch((error) => {
      logger.error('Failed to notify admins about newly created report', {
        reportId: String(report._id),
        error: error.message,
      });
    });

    res.status(201).json(serializeReport(report));
  } catch (err) {
    next(err);
  }
}

async function listReports(req, res, next) {
  try {
    const query = { isDeleted: false };
    const privacy = getPrivacySettings(req.user);
    const selfAnonId = req.user?.anonymousId || (req.user?._id ? String(req.user._id) : '');

    if (req.query.type) query.type = req.query.type;
    if (req.query.riskLevel) query.riskLevel = req.query.riskLevel;

    if (privacy.profile_visibility === 'anonymous' && req.user?.anonymousId) {
      query.reporterAnonId = req.user.anonymousId;
    } else {
      const orFilters = [];
      if (req.user?._id) {
        orFilters.push({ reporterUser: req.user._id });
      }
      if (selfAnonId) {
        orFilters.push({ reporterAnonId: selfAnonId });
      }
      if (orFilters.length > 0) {
        query.$or = orFilters;
      }
    }

    const reports = await Report.find(query).populate('emotionAnalysis').sort({ createdAt: -1 }).limit(100);
    res.json(reports.map((report) => serializeReport(report)));
  } catch (err) {
    next(err);
  }
}

module.exports = { createReport, listReports };
