const Report = require('../models/Report');
const AuditLog = require('../models/AuditLog');
const logger = require('../config/logger');
const { buildSuccessResponse } = require('../utils/responseHelpers');

function parseInteger(value, fallback) {
  const parsed = Number(value);
  return Number.isInteger(parsed) && parsed > 0 ? parsed : fallback;
}

async function listAdminReports(req, res, next) {
  try {
    const page = parseInteger(req.query.page, 1);
    const limit = Math.min(parseInteger(req.query.limit, 20), 50);
    const sortBy = ['createdAt', 'riskLevel', 'type', 'status'].includes(req.query.sortBy)
      ? req.query.sortBy
      : 'createdAt';
    const sortOrder = req.query.sortOrder === 'asc' ? 1 : -1;

    const filters = { isDeleted: false };
    if (typeof req.query.status === 'string' && req.query.status.trim().length > 0) {
      filters.status = req.query.status.trim();
    }
    if (typeof req.query.type === 'string' && req.query.type.trim().length > 0) {
      filters.type = req.query.type.trim();
    }
    if (typeof req.query.severity === 'string' && req.query.severity.trim().length > 0) {
      filters.riskLevel = req.query.severity.trim();
    }

    const createdAtFilter = {};
    if (typeof req.query.fromDate === 'string' && req.query.fromDate.trim().length > 0) {
      const fromDate = new Date(req.query.fromDate);
      if (!Number.isNaN(fromDate.getTime())) {
        createdAtFilter.$gte = fromDate;
      }
    }
    if (typeof req.query.toDate === 'string' && req.query.toDate.trim().length > 0) {
      const toDate = new Date(req.query.toDate);
      if (!Number.isNaN(toDate.getTime())) {
        createdAtFilter.$lte = toDate;
      }
    }
    if (Object.keys(createdAtFilter).length > 0) {
      filters.createdAt = createdAtFilter;
    }

    const [items, total] = await Promise.all([
      Report.find(filters)
        .sort({ [sortBy]: sortOrder })
        .skip((page - 1) * limit)
        .limit(limit)
        .lean(),
      Report.countDocuments(filters),
    ]);

    logger.info('Admin report page loaded', {
      adminId: req.user?._id?.toString(),
      filters,
      page,
      limit,
    });

    return res.json(
      buildSuccessResponse(
        {
          items,
          page,
          pageSize: limit,
          total,
        },
        'Admin reports loaded successfully.'
      )
    );
  } catch (err) {
    logger.error('Admin reports load failed', {
      adminId: req.user?._id?.toString(),
      error: err.message,
      stack: err.stack,
    });
    return next(err);
  }
}

async function updateReportStatus(req, res, next) {
  try {
    const reportId = req.params.id;
    const status = typeof req.body.status === 'string' ? req.body.status.trim() : null;
    if (!status) {
      return res.status(400).json({ success: false, message: 'Status is required.' });
    }

    const report = await Report.findById(reportId);
    if (!report) {
      return res.status(404).json({ success: false, message: 'Report not found.' });
    }

    const previousStatus = report.status;
    report.status = status;
    await report.save();

    await AuditLog.create({
      actor: req.user?._id,
      actorAnonId: req.user?.anonymousId,
      action: 'update_report_status',
      resource: 'Report',
      resourceId: report._id,
      ip: req.ip,
      meta: {
        previousStatus,
        newStatus: report.status,
      },
    });

    return res.json({ success: true, message: 'Report status updated.', data: { id: String(report._id), status: report.status } });
  } catch (err) {
    logger.error('Update report status failed', { adminId: req.user?._id?.toString(), error: err.message });
    return next(err);
  }
}

async function deleteReport(req, res, next) {
  try {
    const reportId = req.params.id;
    const report = await Report.findById(reportId);
    if (!report) {
      return res.status(404).json({ success: false, message: 'Report not found.' });
    }

    if (report.isDeleted) {
      return res.status(400).json({ success: false, message: 'Report already deleted.' });
    }

    report.isDeleted = true;
    report.deletedAt = new Date();
    report.deletedBy = req.user?._id;
    await report.save();

    await AuditLog.create({
      actor: req.user?._id,
      actorAnonId: req.user?.anonymousId,
      action: 'delete_report',
      resource: 'Report',
      resourceId: report._id,
      ip: req.ip,
      meta: { status: report.status, incidentType: report.incidentType },
    });

    return res.json({ success: true, message: 'Report deleted.', data: { id: String(report._id) } });
  } catch (err) {
    logger.error('Delete report failed', { adminId: req.user?._id?.toString(), error: err.message });
    return next(err);
  }
}

module.exports = {
  listAdminReports,
  updateReportStatus,
  deleteReport,
};
