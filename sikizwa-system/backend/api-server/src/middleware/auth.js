const jwt = require('jsonwebtoken');
const logger = require('../config/logger');
const { ApiError } = require('../utils/apiError');
const { AUTH_ERRORS } = require('../utils/errorMessages');
const Device = require('../models/Device');
const User = require('../models/User');

function createAuthError({ statusCode = 401, message = AUTH_ERRORS.unauthorized.message, errorCode = AUTH_ERRORS.unauthorized.errorCode }) {
  return new ApiError({ statusCode, message, errorCode });
}

function logAuthFailure(reason, req) {
  logger.warn('Authentication failed', {
    reason,
    method: req.method,
    path: req.originalUrl,
    ip: req.ip,
  });
}

function normalizeJwtError(err) {
  if (err instanceof jwt.TokenExpiredError) {
    return {
      statusCode: 401,
      message: AUTH_ERRORS.tokenExpired.message,
      errorCode: AUTH_ERRORS.tokenExpired.errorCode,
      reason: 'TOKEN_EXPIRED',
    };
  }

  if (err instanceof jwt.JsonWebTokenError) {
    return {
      statusCode: 401,
      message: AUTH_ERRORS.invalidCredentials.message,
      errorCode: 'AUTH_INVALID_SIGNATURE',
      reason: 'INVALID_SIGNATURE',
    };
  }

  return {
    statusCode: 401,
    message: AUTH_ERRORS.invalidCredentials.message,
    errorCode: 'AUTH_INVALID_SIGNATURE',
    reason: 'INVALID_SIGNATURE',
  };
}

function isTokenRevoked(user, tokenIat) {
  if (!user || !user.passwordChangedAt) {
    return false;
  }

  const issuedAt = typeof tokenIat === 'number' ? tokenIat * 1000 : Number(tokenIat);
  if (!Number.isFinite(issuedAt)) {
    return false;
  }

  return new Date(user.passwordChangedAt).getTime() > issuedAt;
}

async function requireAuth(req, res, next) {
  const auth = req.headers.authorization;
  if (!auth) {
    logAuthFailure('TOKEN_MISSING', req);
    return next(createAuthError({ message: AUTH_ERRORS.unauthorized.message, errorCode: 'AUTH_TOKEN_MISSING' }));
  }

  const token = auth.split(' ')[1];
  if (!token) {
    logAuthFailure('TOKEN_MISSING', req);
    return next(createAuthError({ message: AUTH_ERRORS.unauthorized.message, errorCode: 'AUTH_TOKEN_MISSING' }));
  }

  try {
    const payload = jwt.verify(token, process.env.JWT_SECRET);

    if (payload.deviceId) {
      const device = await Device.findOne({ deviceId: payload.deviceId, userId: payload.sub, isActive: true });
      if (!device) {
        logAuthFailure('DEVICE_NOT_AUTHORIZED', req);
        return next(createAuthError({ message: AUTH_ERRORS.unauthorized.message, errorCode: 'AUTH_DEVICE_NOT_AUTHORIZED' }));
      }
    }

    const user = await User.findById(payload.sub).select('-passwordHash');
    if (!user) {
      logAuthFailure('USER_NOT_FOUND', req);
      return next(createAuthError({ message: AUTH_ERRORS.invalidCredentials.message, errorCode: 'AUTH_USER_NOT_FOUND' }));
    }

    if (isTokenRevoked(user, payload.iat)) {
      logAuthFailure('TOKEN_REVOKED', req);
      return next(createAuthError({ statusCode: 401, message: AUTH_ERRORS.invalidCredentials.message, errorCode: 'AUTH_TOKEN_REVOKED' }));
    }

    req.user = user;
    next();
  } catch (err) {
    const normalized = normalizeJwtError(err);
    logAuthFailure(normalized.reason, req);
    return next(createAuthError({ statusCode: normalized.statusCode, message: normalized.message, errorCode: normalized.errorCode }));
  }
}

function requireRole(role) {
  return (req, res, next) => {
    if (!req.user) {
      return next(createAuthError({ statusCode: 403, message: AUTH_ERRORS.forbidden.message, errorCode: AUTH_ERRORS.forbidden.errorCode }));
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
      return next(createAuthError({ statusCode: 403, message: AUTH_ERRORS.forbidden.message, errorCode: AUTH_ERRORS.forbidden.errorCode }));
    }

    next();
  };
}

function requirePermission(permission) {
  return (req, res, next) => {
    if (!req.user) {
      return next(createAuthError({ statusCode: 403, message: AUTH_ERRORS.forbidden.message, errorCode: AUTH_ERRORS.forbidden.errorCode }));
    }

    if (req.user.role === 'super_admin') {
      return next();
    }

    const permissions = Array.isArray(req.user.permissions) ? req.user.permissions : [];
    if (!permissions.includes(permission)) {
      return next(createAuthError({ statusCode: 403, message: AUTH_ERRORS.forbidden.message, errorCode: AUTH_ERRORS.forbidden.errorCode }));
    }

    next();
  };
}

const verifyAdminToken = requireAuth;
const requireAdminRole = requireRole;
const requireSuperAdmin = requireRole('super_admin');

module.exports = { requireAuth, requireRole, requirePermission, verifyAdminToken, requireAdminRole, requireSuperAdmin };
