const express = require('express');
const router = express.Router();
const { requireAuth } = require('../middleware/auth');
const safeSpaceController = require('../controllers/safeSpaceController');
const validate = require('../middleware/validate');
const { resourceSchema } = require('../validators/contentValidator');

router.get('/', requireAuth, safeSpaceController.listSafeSpaces);
router.post('/', requireAuth, validate(resourceSchema), safeSpaceController.createSafeSpace);

module.exports = router;
