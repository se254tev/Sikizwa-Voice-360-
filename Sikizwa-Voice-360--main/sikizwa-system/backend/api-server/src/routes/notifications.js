const express = require('express');
const router = express.Router();
const { requireAuth } = require('../middleware/auth');
const notificationController = require('../controllers/notificationController');

router.get('/', requireAuth, notificationController.listNotifications);
router.patch('/:id/read', requireAuth, notificationController.markRead);

module.exports = router;
