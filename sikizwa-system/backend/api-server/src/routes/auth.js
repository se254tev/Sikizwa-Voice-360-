const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const validate = require('../middleware/validate');
const { registerSchema, loginSchema, forgotPasswordSchema, verifyOtpSchema, resetPasswordSchema, refreshSchema } = require('../validators/authValidator');
const { authLoginLimiter } = require('../middleware/rateLimit');

router.post('/anonymous', authController.anonymousLogin);
router.post(
  '/register',
  validate(registerSchema, {
    includeDetails: false,
    failureMessage: 'Unable to create account',
    failureCode: 'AUTH_SIGNUP_FAILED',
    statusCode: 400,
  }),
  authController.register
);
router.post(
  '/login',
  authLoginLimiter,
  validate(loginSchema, {
    includeDetails: false,
    failureMessage: 'Invalid credentials',
    failureCode: 'AUTH_INVALID_CREDENTIALS',
    statusCode: 401,
  }),
  authController.login
);
router.post('/forgot-password', validate(forgotPasswordSchema), authController.forgotPassword);
router.post('/verify-otp', validate(verifyOtpSchema), authController.verifyOtp);
router.post('/reset-password', validate(resetPasswordSchema), authController.resetPassword);
router.post('/refresh', validate(refreshSchema), authController.refreshToken);

module.exports = router;
