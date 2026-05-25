const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const validate = require('../middleware/validate');
const { registerSchema, loginSchema, refreshSchema } = require('../validators/authValidator');
const { authLoginLimiter } = require('../middleware/rateLimit');

router.post('/anonymous', authController.anonymousLogin);
router.post('/register', validate(registerSchema), authController.register);
router.post('/login', authLoginLimiter, validate(loginSchema), authController.login);
router.post('/refresh', validate(refreshSchema), authController.refreshToken);

module.exports = router;
