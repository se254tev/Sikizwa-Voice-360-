const express = require('express');
const deviceController = require('../controllers/deviceController');

const router = express.Router();

router.post('/link', deviceController.linkDevice);
router.post('/issue', deviceController.issuePairingCode);
router.post('/logout', deviceController.logoutDevice);

module.exports = router;
