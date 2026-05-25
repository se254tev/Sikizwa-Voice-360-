const jwt = require('jsonwebtoken');
const Device = require('../models/Device');
const User = require('../models/User');

async function requireAuth(req, res, next) {
  const auth = req.headers.authorization;
  if (!auth) {
    return res.status(401).json({ error: 'missing auth' });
  }

  const token = auth.split(' ')[1];

  try {
    const payload = jwt.verify(token, process.env.JWT_SECRET);

    if (payload.deviceId) {
      const device = await Device.findOne({ deviceId: payload.deviceId, userId: payload.sub, isActive: true });
      if (!device) {
        return res.status(401).json({ error: 'device not authorized' });
      }
    }

    req.user = await User.findById(payload.sub).select('-passwordHash');
    next();
  } catch (err) {
    return res.status(401).json({ error: 'invalid token' });
  }
}

function requireRole(role) {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(403).json({ error: 'forbidden' });
    }

    const allowedRoles = Array.isArray(role) ? role : [role];
    const normalizedRoles = new Set();

    allowedRoles.forEach((allowedRole) => {
      if (allowedRole === 'admin') {
        normalizedRoles.add('admin');
        normalizedRoles.add('super_admin');
      } else {
        normalizedRoles.add(allowedRole);
      }
    });

    if (!normalizedRoles.has(req.user.role)) {
      return res.status(403).json({ error: 'forbidden' });
    }

    next();
  };
}

function requirePermission(permission) {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(403).json({ error: 'forbidden' });
    }

    if (req.user.role === 'super_admin') {
      return next();
    }

    const permissions = Array.isArray(req.user.permissions) ? req.user.permissions : [];
    if (!permissions.includes(permission)) {
      return res.status(403).json({ error: 'forbidden' });
    }

    next();
  };
}

const verifyAdminToken = requireAuth;
const requireAdminRole = requireRole;
const requireSuperAdmin = requireRole('super_admin');

module.exports = { requireAuth, requireRole, requirePermission, verifyAdminToken, requireAdminRole, requireSuperAdmin };
