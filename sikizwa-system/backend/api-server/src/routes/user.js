const express = require('express');
const router = express.Router();
const { requireAuth } = require('../middleware/auth');
const validate = require('../middleware/validate');
const userPreferencesController = require('../controllers/userPreferencesController');
const userController = require('../controllers/userController');
const { trustedPendantSchema, emergencyContactsSchema } = require('../validators/userValidator');

router.get('/preferences', requireAuth, userPreferencesController.getUserPreferencesHandler);
router.patch('/preferences', requireAuth, userPreferencesController.patchUserPreferencesHandler);
router.get('/emergency-contacts', requireAuth, userController.getEmergencyContacts);
router.put('/emergency-contacts', requireAuth, validate(emergencyContactsSchema), userController.saveEmergencyContacts);
router.post('/trusted-pendants', requireAuth, validate(trustedPendantSchema), userController.registerTrustedPendant);

module.exports = router;
