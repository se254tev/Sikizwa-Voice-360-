const express = require('express');
const rateLimit = require('express-rate-limit');
const { requireAuth } = require('../middleware/auth');
const distressSignalController = require('../controllers/distressSignalController');

const router = express.Router();

const distressLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 5,
  standardHeaders: true,
  legacyHeaders: false,
});

router.post('/', requireAuth, distressLimiter, distressSignalController.createDistressSignal);

module.exports = router;
