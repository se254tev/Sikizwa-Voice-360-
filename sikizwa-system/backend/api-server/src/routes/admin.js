const express = require('express');
const rateLimit = require('express-rate-limit');
const adminController = require('../controllers/adminController');
const adminReportController = require('../controllers/adminReportController');
const validate = require('../middleware/validate');
const { verifyAdminToken, requireAdminRole, requireSuperAdmin } = require('../middleware/auth');
const { adminSignupSchema, adminLoginSchema, reportStatusSchema } = require('../validators/adminValidator');

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
router.get('/reports', verifyAdminToken, requireAdminRole('admin'), adminReportController.listAdminReports);
router.patch('/reports/:id/status', verifyAdminToken, requireAdminRole('admin'), validate(reportStatusSchema), adminReportController.updateReportStatus);
router.delete('/reports/:id', verifyAdminToken, requireSuperAdmin, adminReportController.deleteReport);

module.exports = router;
