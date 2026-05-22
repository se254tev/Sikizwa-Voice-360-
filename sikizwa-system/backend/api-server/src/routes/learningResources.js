const express = require('express');
const router = express.Router();
const { requireAuth } = require('../middleware/auth');
const learningResourceController = require('../controllers/learningResourceController');
const validate = require('../middleware/validate');
const { resourceSchema } = require('../validators/contentValidator');

router.get('/', requireAuth, learningResourceController.listResources);
router.post('/', requireAuth, validate(resourceSchema), learningResourceController.createResource);

module.exports = router;
