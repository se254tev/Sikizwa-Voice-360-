const express = require('express');
const multer = require('multer');
const uploadController = require('../controllers/uploadController');
const { requireAuth } = require('../middleware/auth');

const storage = multer.memoryStorage();
const upload = multer({ storage, limits: { fileSize: 20 * 1024 * 1024 } });

const router = express.Router();
router.post('/', requireAuth, upload.single('file'), uploadController.uploadFile);

module.exports = router;
