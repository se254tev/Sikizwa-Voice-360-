const express = require('express');
const rateLimit = require('express-rate-limit');
const adminController = require('../controllers/adminController');
const validate = require('../middleware/validate');
const { verifyAdminToken, requireAdminRole } = require('../middleware/auth');
const { adminSignupSchema, adminLoginSchema } = require('../validators/adminValidator');

const router = express.Router();

const adminLoginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5,
  standardHeaders: true,
  legacyHeaders: false,
  message: { success: false, message: 'Too many login attempts. Please try again later.' },
});

router.post('/signup', validate(adminSignupSchema), adminController.signup);
router.post('/login', adminLoginLimiter, validate(adminLoginSchema), adminController.login);
router.post('/logout', verifyAdminToken, requireAdminRole('admin'), adminController.logout);
router.get('/profile', verifyAdminToken, requireAdminRole('admin'), adminController.profile);

module.exports = router;
