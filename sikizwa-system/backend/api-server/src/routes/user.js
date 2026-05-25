const express = require('express');
const router = express.Router();
const { requireAuth } = require('../middleware/auth');
const validate = require('../middleware/validate');
const userPreferencesController = require('../controllers/userPreferencesController');
const userController = require('../controllers/userController');
const { trustedPendantSchema } = require('../validators/userValidator');

router.get('/preferences', requireAuth, userPreferencesController.getUserPreferencesHandler);
router.patch('/preferences', requireAuth, userPreferencesController.patchUserPreferencesHandler);
router.post('/trusted-pendants', requireAuth, validate(trustedPendantSchema), userController.registerTrustedPendant);

module.exports = router;
