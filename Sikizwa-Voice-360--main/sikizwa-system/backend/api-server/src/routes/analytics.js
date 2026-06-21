const express = require('express');
const router = express.Router();
const { requireAuth, requireRole } = require('../middleware/auth');
const analyticsController = require('../controllers/analyticsController');

router.get('/overview', requireAuth, requireRole('admin'), analyticsController.overview);
router.get('/reports/trends', requireAuth, requireRole('admin'), analyticsController.reportTrends);

module.exports = router;
