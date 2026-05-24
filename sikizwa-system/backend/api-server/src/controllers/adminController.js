const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const logger = require('../config/logger');

function signToken(payload, secret, expiresIn = '60m') {
  return jwt.sign(payload, secret, { expiresIn });
}

function buildAdminResponse(user) {
  return {
    id: user._id,
    fullName: user.fullName,
    phoneNumber: user.phoneNumber || user.phone,
    email: user.email,
    nationalId: user.nationalId,
    role: user.role,
    createdAt: user.createdAt,
    updatedAt: user.updatedAt,
  };
}

function getOrigin(req) {
  return req.get('origin') || req.get('referer') || 'unknown';
}

function getAdminSecretHeader(req) {
  const adminSecret = req.headers['x-admin-secret'];
  return typeof adminSecret === 'string' ? adminSecret : '';
}

function buildSecurityLog(req, extra = {}) {
  return {
    method: req.method,
    path: req.originalUrl,
    origin: getOrigin(req),
    headers: {
      authorization: req.headers.authorization ? 'present' : 'missing',
      'x-admin-secret': getAdminSecretHeader(req) ? 'present' : 'missing',
    },
    reqUser: req.user
      ? {
          id: req.user._id.toString(),
          role: req.user.role,
        }
      : null,
    ...extra,
  };
}

function forbiddenResponse(res, message) {
  return res.status(403).json({
    success: false,
    message,
    errorCode: 'FORBIDDEN_ACCESS',
  });
}

async function authorizeAdminSignup(req) {
  const adminCount = await User.countDocuments({ role: 'admin' });

  if (adminCount === 0) {
    return { allowed: true, reason: 'bootstrap' };
  }

  const bearerToken = req.headers.authorization;

  if (bearerToken && bearerToken.startsWith('Bearer ')) {
    try {
      const payload = jwt.verify(bearerToken.slice(7), process.env.JWT_SECRET);
      if (!payload?.sub) {
        return { allowed: false, reason: 'authenticated token missing sub claim' };
      }

      const currentUser = await User.findById(payload.sub).select('-passwordHash');
      if (currentUser && currentUser.role === 'admin') {
        req.user = currentUser;
        return { allowed: true, reason: 'authenticated-admin' };
      }

      return { allowed: false, reason: 'authenticated token does not belong to an admin user' };
    } catch (err) {
      return { allowed: false, reason: `invalid admin token: ${err.message}` };
    }
  }

  const adminSecret = getAdminSecretHeader(req);
  const expectedSecret = process.env.ADMIN_SIGNUP_SECRET || '';

  if (expectedSecret && adminSecret === expectedSecret) {
    return { allowed: true, reason: 'admin-secret' };
  }

  return {
    allowed: false,
    reason: 'existing admins require an authenticated admin token or a valid X-Admin-Secret header',
  };
}

async function signup(req, res, next) {
  try {
    const authDecision = await authorizeAdminSignup(req);

    if (!authDecision.allowed) {
      logger.warn(
        buildSecurityLog(req, {
          rejectedAuthorizationReason: authDecision.reason,
        }),
        'Admin signup rejected'
      );

      return forbiddenResponse(
        res,
        'Admin sign-up is restricted. Sign in with an authenticated admin account or provide a valid X-Admin-Secret header.'
      );
    }

    logger.info(
      buildSecurityLog(req, {
        authorizationDecision: authDecision.reason,
      }),
      'Admin signup authorization approved'
    );

    const { fullName, phoneNumber, email, nationalId, password } = req.body;

    const existing = await User.findOne({
      $or: [
        { email },
        { phoneNumber },
        { nationalId },
      ],
    });

    if (existing) {
      return res.status(409).json({
        success: false,
        message: 'An admin with that email, phone number, or national ID already exists',
        errorCode: 'DB_RECORD_CONFLICT',
      });
    }

    const passwordHash = await bcrypt.hash(password, 12);

    const admin = await User.create({
      fullName,
      phoneNumber,
      phone: phoneNumber,
      email,
      nationalId,
      passwordHash,
      role: 'admin',
    });

    const token = signToken({ sub: admin._id, role: admin.role }, process.env.JWT_SECRET, process.env.JWT_EXPIRES_IN || '60m');

    return res.status(201).json({
      success: true,
      message: 'Admin account created successfully',
      token,
      admin: buildAdminResponse(admin),
    });
  } catch (err) {
    if (err.code === 11000) {
      return res.status(409).json({
        success: false,
        message: 'An admin with that email, phone number, or national ID already exists',
        errorCode: 'DB_RECORD_CONFLICT',
      });
    }

    logger.error(
      buildSecurityLog(req, {
        errorMessage: err.message,
      }),
      'Admin signup failed'
    );

    return next(err);
  }
}

async function login(req, res, next) {
  try {
    const { identifier, password } = req.body;
    const user = await User.findOne({
      $or: [
        { email: identifier },
        { phoneNumber: identifier },
        { phone: identifier },
      ],
    });

    if (!user || user.role !== 'admin') {
      return res.status(401).json({ success: false, message: 'Invalid admin credentials' });
    }

    const validPassword = await bcrypt.compare(password, user.passwordHash || '');
    if (!validPassword) {
      return res.status(401).json({ success: false, message: 'Invalid admin credentials' });
    }

    const token = signToken({ sub: user._id, role: user.role }, process.env.JWT_SECRET, process.env.JWT_EXPIRES_IN || '60m');

    return res.json({
      success: true,
      message: 'Admin login successful',
      token,
      admin: buildAdminResponse(user),
    });
  } catch (err) {
    return next(err);
  }
}

async function logout(req, res, next) {
  try {
    return res.json({ success: true, message: 'Admin logged out successfully' });
  } catch (err) {
    return next(err);
  }
}

async function profile(req, res, next) {
  try {
    if (!req.user || req.user.role !== 'admin') {
      return res.status(403).json({ success: false, message: 'Access denied' });
    }

    return res.json({
      success: true,
      admin: buildAdminResponse(req.user),
    });
  } catch (err) {
    return next(err);
  }
}

module.exports = { signup, login, logout, profile };