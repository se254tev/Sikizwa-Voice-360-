const express = require('express');
const router = express.Router();
const { requireAuth } = require('../middleware/auth');
const emergencyController = require('../controllers/emergencyController');
const validate = require('../middleware/validate');
const { emergencySchema } = require('../validators/emergencyValidator');

router.post('/', requireAuth, validate(emergencySchema), emergencyController.createEmergency);
router.get('/', requireAuth, emergencyController.listEmergencies);
router.patch('/:id/resolve', requireAuth, emergencyController.resolveEmergency);

module.exports = router;
