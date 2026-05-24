const express = require('express');
const { requireAuth, requireRole } = require('../middleware/auth');
const distressSignalController = require('../controllers/distressSignalController');

const router = express.Router();

router.get('/', requireAuth, requireRole('admin'), distressSignalController.listDistressSignals);

module.exports = router;
