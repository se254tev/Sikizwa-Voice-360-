const express = require('express');
const router = express.Router();
const { requireAuth } = require('../middleware/auth');
const counsellorController = require('../controllers/counsellorController');

router.get('/', requireAuth, counsellorController.listCounsellors);
router.post('/match', requireAuth, counsellorController.matchCounsellor);

module.exports = router;
