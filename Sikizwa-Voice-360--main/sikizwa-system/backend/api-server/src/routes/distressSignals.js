const express = require('express');
const { requireAuth } = require('../middleware/auth');
const distressSignalController = require('../controllers/distressSignalController');
const { idempotencyMiddleware } = require('../middleware/idempotency');
const { emergencyLimiter } = require('../middleware/rateLimit');

const router = express.Router();

router.post('/', requireAuth, emergencyLimiter, idempotencyMiddleware(30), distressSignalController.createDistressSignal);

module.exports = router;
