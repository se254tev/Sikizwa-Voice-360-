const express = require('express');
const router = express.Router();
const { requireAuth } = require('../middleware/auth');
const reportController = require('../controllers/reportController');
const validate = require('../middleware/validate');
const { reportSchema } = require('../validators/reportValidator');
const { reportLimiter } = require('../middleware/rateLimit');
const logger = require('../config/logger');

function logIncomingReportRequest(req, res, next) {
  logger.info('Incoming POST /api/reports request', {
    userId: req.user?._id ? String(req.user._id) : null,
    body: {
      reportType: req.body.reportType,
      incidentType: req.body.incidentType,
      descriptionLength: typeof req.body.description === 'string' ? req.body.description.length : null,
      anonymousSubmission: req.body.anonymousSubmission,
      priority: req.body.priority,
      location: req.body.location,
    },
  });

  return next();
}

router.post('/', requireAuth, reportLimiter, validate(reportSchema), logIncomingReportRequest, reportController.createReport);
router.get('/', requireAuth, reportController.listReports);

module.exports = router;
