const express = require('express');
const router = express.Router();
const { requireAuth } = require('../middleware/auth');
const supportChatController = require('../controllers/supportChatController');

router.post('/', requireAuth, supportChatController.createChat);
router.get('/', requireAuth, supportChatController.listChats);
router.post('/:id/message', requireAuth, supportChatController.sendMessage);

module.exports = router;
