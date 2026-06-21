const express = require('express');
const multer = require('multer');
const router = express.Router();
const { requireAuth } = require('../middleware/auth');
const aiController = require('../controllers/aiController');
const { aiLimiter } = require('../middleware/rateLimit');

const upload = multer({ storage: multer.memoryStorage(), limits: { fileSize: 25 * 1024 * 1024 } });

router.post('/transcribe', requireAuth, upload.single('file'), aiController.transcribe);
router.post('/emotion-analysis', requireAuth, upload.single('file'), aiController.emotionAnalysis);
router.post('/risk-score', requireAuth, aiController.riskScore);
router.post('/chat', requireAuth, aiLimiter, aiController.chat);

module.exports = router;
