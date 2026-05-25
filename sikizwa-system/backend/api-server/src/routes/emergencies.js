const express = require('express');
const router = express.Router();
const { requireAuth } = require('../middleware/auth');
const emergencyController = require('../controllers/emergencyController');
const validate = require('../middleware/validate');
const { emergencySchema } = require('../validators/emergencyValidator');
const { emergencyLimiter } = require('../middleware/rateLimit');

router.post('/', requireAuth, emergencyLimiter, validate(emergencySchema), emergencyController.createEmergency);
router.get('/', requireAuth, emergencyController.listEmergencies);
router.patch('/:id/resolve', requireAuth, emergencyController.resolveEmergency);

module.exports = router;
