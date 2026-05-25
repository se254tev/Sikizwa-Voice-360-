const express = require('express');
const router = express.Router();
const { requireAuth } = require('../middleware/auth');
const reportController = require('../controllers/reportController');
const validate = require('../middleware/validate');
const { reportSchema } = require('../validators/reportValidator');
const { reportLimiter } = require('../middleware/rateLimit');

router.post('/', requireAuth, reportLimiter, validate(reportSchema), reportController.createReport);
router.get('/', requireAuth, reportController.listReports);

module.exports = router;
