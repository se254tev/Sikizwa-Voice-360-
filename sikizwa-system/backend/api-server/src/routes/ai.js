const express = require('express');
const multer = require('multer');
const router = express.Router();
const { requireAuth } = require('../middleware/auth');
const aiController = require('../controllers/aiController');

const upload = multer({ storage: multer.memoryStorage(), limits: { fileSize: 25 * 1024 * 1024 } });

router.post('/transcribe', requireAuth, upload.single('file'), aiController.transcribe);
router.post('/emotion-analysis', requireAuth, upload.single('file'), aiController.emotionAnalysis);
router.post('/risk-score', requireAuth, aiController.riskScore);
router.post('/chat', requireAuth, aiController.chat);

module.exports = router;
