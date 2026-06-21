const express = require('express');
const { requireAuth } = require('../middleware/auth');
const { createPendantSOS, updatePendantLocation } = require('../controllers/pendantEmergencyController');
const { emergencyLimiter } = require('../middleware/rateLimit');
const { idempotencyMiddleware } = require('../middleware/idempotency');

const router = express.Router();

router.post('/pendant-sos', requireAuth, emergencyLimiter, idempotencyMiddleware(30), createPendantSOS);
router.post('/location-update', requireAuth, emergencyLimiter, idempotencyMiddleware(30), updatePendantLocation);

module.exports = router;
