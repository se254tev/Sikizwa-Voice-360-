const axios = require('axios');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const bcrypt = require('bcrypt');
const logger = require('../config/logger');
const { ApiError } = require('../utils/apiError');
const { AUTH_ERRORS, VALIDATION_ERRORS, DB_ERRORS } = require('../utils/errorMessages');
const Device = require('../models/Device');
const User = require('../models/User');

const PASSWORD_STRENGTH = /^(?=.*[A-Za-z])(?=.*\d).{8,}$/;
const RESET_OTP_TTL_MS = 10 * 60 * 1000;
const RESET_OTP_LOCK_MS = 15 * 60 * 1000;
const RESET_OTP_LIMIT = 5;

function signToken(payload, secret, expiresIn = '15m') {
  return jwt.sign(payload, secret, { expiresIn });
}

function normalizeRole(role) {
  const allowed = ['user', 'counsellor', 'admin', 'responder', 'other'];
  return allowed.includes(role) ? role : 'other';
}

function normalizePhone(value) {
  const phone = typeof value === 'string' ? value.trim() : '';
  if (!/^\+?[0-9]{7,15}$/.test(phone)) {
    throw new ApiError({
      statusCode: 400,
      message: 'phone must be a valid international number',
      errorCode: VALIDATION_ERRORS.invalidFormat.errorCode,
    });
  }

  return phone;
}

function normalizeDeviceType(value) {
  if (!value) {
    return null;
  }

  const normalized = value.toString().trim();
  if (!['phone', 'tablet', 'tv', 'watch'].includes(normalized)) {
    throw new ApiError({
      statusCode: 400,
      message: 'device_type must be phone, tablet, tv, or watch',
      errorCode: VALIDATION_ERRORS.invalidFormat.errorCode,
    });
  }

  return normalized;
}

function normalizePassword(password) {
  const trimmed = typeof password === 'string' ? password.trim() : '';
  if (!PASSWORD_STRENGTH.test(trimmed)) {
    throw new ApiError({
      statusCode: 400,
      message: 'password must be at least 8 characters and include at least one letter and one number',
      errorCode: VALIDATION_ERRORS.invalidFormat.errorCode,
    });
  }

  return trimmed;
}

function createOtp() {
  return String(Math.floor(100000 + Math.random() * 900000));
}

function clearResetOtp(user) {
  user.resetOtpHash = null;
  user.resetOtpExpiresAt = null;
  user.resetOtpAttempts = 0;
  user.resetOtpLockedUntil = null;
  user.resetOtpVerifiedAt = null;
}

async function sendOtpSms(phone, otp) {
  const smsUrl = process.env.RESET_SMS_URL;
  const smsToken = process.env.RESET_SMS_TOKEN;

  if (!smsUrl) {
    logger.info('Password reset OTP generated (SMS provider not configured)', {
      phone,
      otp,
    });
    return;
  }

  try {
    await axios.post(
      smsUrl,
      {
        phone,
        otp,
        template: 'Your Sikizwa reset code is {{otp}}',
      },
      {
        headers: smsToken
          ? {
              Authorization: `Bearer ${smsToken}`,
            }
          : undefined,
      }
    );
  } catch (err) {
    logger.warn('Failed to send password reset SMS', {
      phone,
      error: err.message,
    });
  }
}

async function upsertDevice(deviceId, deviceType, userId) {
  if (!deviceId || !deviceType) {
    return null;
  }

  await Device.findOneAndUpdate(
    { deviceId },
    {
      userId,
      deviceId,
      deviceType,
      pairedAt: new Date(),
      isPrimary: false,
      isActive: true,
    },
    { upsert: true, new: true }
  );

  return true;
}

async function anonymousLogin(req, res, next) {
  try {
    const anonId = 'anon_' + crypto.randomBytes(16).toString('hex');
    const user = await User.create({ anonymousId: anonId });
    const access = signToken({ sub: user._id, role: user.role }, process.env.JWT_SECRET);
    const refresh = signToken({ sub: user._id, role: user.role }, process.env.JWT_REFRESH_SECRET, '30d');
    return res.json({ access, refresh, anonymousId: anonId });
  } catch (err) {
    return next(err);
  }
}

async function register(req, res, next) {
  try {
    const { fullName, phone, password, device_id, device_type } = req.body;

    if (!fullName || !phone || !password) {
      throw new ApiError({
        statusCode: 400,
        message: 'Unable to create account',
        errorCode: 'AUTH_SIGNUP_FAILED',
      });
    }

    const normalizedPhone = normalizePhone(phone);
    const normalizedType = normalizeDeviceType(device_type);
    const normalizedPassword = normalizePassword(password);

    const hash = await bcrypt.hash(normalizedPassword, 12);
    const user = await User.create({
      name: fullName,
      fullName,
      phone: normalizedPhone,
      username: normalizedPhone,
      passwordHash: hash,
      passwordChangedAt: new Date(),
      role: 'other',
    });

    await upsertDevice(device_id, normalizedType, user._id);

    const access = signToken({ sub: user._id, role: user.role, deviceId: device_id || undefined }, process.env.JWT_SECRET);
    const refresh = signToken(
      { sub: user._id, role: user.role, deviceId: device_id || undefined },
      process.env.JWT_REFRESH_SECRET,
      '30d'
    );

    return res.json({ access, refresh });
  } catch (err) {
    if (err.code === 11000) {
      return next(
        new ApiError({
          statusCode: 409,
          message: 'Unable to create account',
          errorCode: 'AUTH_SIGNUP_FAILED',
        })
      );
    }

    return next(err);
  }
}

async function login(req, res, next) {
  try {
    const { identifier, password, device_id, device_type } = req.body;
    if (!identifier || !password) {
      throw new ApiError({
        statusCode: 400,
        message: VALIDATION_ERRORS.missingFields.message,
        errorCode: VALIDATION_ERRORS.missingFields.errorCode,
      });
    }

    const normalizedPhone = normalizePhone(identifier);
    const normalizedType = normalizeDeviceType(device_type);
    const user = await User.findOne({ phone: normalizedPhone });

    if (!user || !user.passwordHash) {
      throw new ApiError({
        statusCode: 401,
        message: AUTH_ERRORS.invalidCredentials.message,
        errorCode: AUTH_ERRORS.invalidCredentials.errorCode,
      });
    }

    const ok = await bcrypt.compare(password.trim(), user.passwordHash);
    if (!ok) {
      throw new ApiError({
        statusCode: 401,
        message: AUTH_ERRORS.invalidCredentials.message,
        errorCode: AUTH_ERRORS.invalidCredentials.errorCode,
      });
    }

    await upsertDevice(device_id, normalizedType, user._id);

    const access = signToken({ sub: user._id, role: user.role, deviceId: device_id || undefined }, process.env.JWT_SECRET);
    const refresh = signToken(
      { sub: user._id, role: user.role, deviceId: device_id || undefined },
      process.env.JWT_REFRESH_SECRET,
      '30d'
    );

    return res.json({ access, refresh });
  } catch (err) {
    return next(err);
  }
}

async function forgotPassword(req, res, next) {
  try {
    const normalizedPhone = normalizePhone(req.body.phone);
    const user = await User.findOne({ phone: normalizedPhone });

    if (user) {
      const otp = createOtp();
      const otpHash = await bcrypt.hash(otp, 12);
      user.resetOtpHash = otpHash;
      user.resetOtpExpiresAt = new Date(Date.now() + RESET_OTP_TTL_MS);
      user.resetOtpAttempts = 0;
      user.resetOtpLockedUntil = null;
      user.resetOtpVerifiedAt = null;
      await user.save();
      await sendOtpSms(normalizedPhone, otp);
    }

    return res.json({
      success: true,
      message: 'If the account exists, a reset code has been sent',
    });
  } catch (err) {
    return next(err);
  }
}

async function verifyOtp(req, res, next) {
  try {
    const { phone, otp } = req.body;

    if (!phone || !otp) {
      throw new ApiError({
        statusCode: 400,
        message: VALIDATION_ERRORS.missingFields.message,
        errorCode: VALIDATION_ERRORS.missingFields.errorCode,
      });
    }

    const normalizedPhone = normalizePhone(phone);
    const user = await User.findOne({ phone: normalizedPhone });

    if (!user || !user.resetOtpHash) {
      throw new ApiError({
        statusCode: 400,
        message: 'Invalid or expired code',
        errorCode: 'AUTH_OTP_INVALID',
      });
    }

    if (user.resetOtpLockedUntil && user.resetOtpLockedUntil > new Date()) {
      throw new ApiError({
        statusCode: 400,
        message: 'Invalid or expired code',
        errorCode: 'AUTH_OTP_INVALID',
      });
    }

    if (!user.resetOtpExpiresAt || user.resetOtpExpiresAt < new Date()) {
      clearResetOtp(user);
      await user.save();
      throw new ApiError({
        statusCode: 400,
        message: 'Invalid or expired code',
        errorCode: 'AUTH_OTP_INVALID',
      });
    }

    const isValidOtp = await bcrypt.compare(String(otp).trim(), user.resetOtpHash);
    if (!isValidOtp) {
      user.resetOtpAttempts = (user.resetOtpAttempts || 0) + 1;
      if (user.resetOtpAttempts >= RESET_OTP_LIMIT) {
        user.resetOtpLockedUntil = new Date(Date.now() + RESET_OTP_LOCK_MS);
      }
      await user.save();
      throw new ApiError({
        statusCode: 400,
        message: 'Invalid or expired code',
        errorCode: 'AUTH_OTP_INVALID',
      });
    }

    user.resetOtpAttempts = 0;
    user.resetOtpLockedUntil = null;
    user.resetOtpVerifiedAt = new Date();
    await user.save();

    return res.json({ success: true, message: 'OTP verified' });
  } catch (err) {
    return next(err);
  }
}

async function resetPassword(req, res, next) {
  try {
    const { phone, otp, password } = req.body;

    if (!phone || !otp || !password) {
      throw new ApiError({
        statusCode: 400,
        message: VALIDATION_ERRORS.missingFields.message,
        errorCode: VALIDATION_ERRORS.missingFields.errorCode,
      });
    }

    const normalizedPhone = normalizePhone(phone);
    const normalizedPassword = normalizePassword(password);
    const user = await User.findOne({ phone: normalizedPhone });

    if (!user || !user.resetOtpHash || !user.resetOtpVerifiedAt) {
      throw new ApiError({
        statusCode: 400,
        message: 'Invalid or expired code',
        errorCode: 'AUTH_OTP_INVALID',
      });
    }

    if (user.resetOtpLockedUntil && user.resetOtpLockedUntil > new Date()) {
      throw new ApiError({
        statusCode: 400,
        message: 'Invalid or expired code',
        errorCode: 'AUTH_OTP_INVALID',
      });
    }

    if (!user.resetOtpExpiresAt || user.resetOtpExpiresAt < new Date()) {
      clearResetOtp(user);
      await user.save();
      throw new ApiError({
        statusCode: 400,
        message: 'Invalid or expired code',
        errorCode: 'AUTH_OTP_INVALID',
      });
    }

    const isValidOtp = await bcrypt.compare(String(otp).trim(), user.resetOtpHash);
    if (!isValidOtp) {
      user.resetOtpAttempts = (user.resetOtpAttempts || 0) + 1;
      if (user.resetOtpAttempts >= RESET_OTP_LIMIT) {
        user.resetOtpLockedUntil = new Date(Date.now() + RESET_OTP_LOCK_MS);
      }
      await user.save();
      throw new ApiError({
        statusCode: 400,
        message: 'Invalid or expired code',
        errorCode: 'AUTH_OTP_INVALID',
      });
    }

    const hash = await bcrypt.hash(normalizedPassword, 12);
    user.passwordHash = hash;
    user.passwordChangedAt = new Date();
    clearResetOtp(user);
    await user.save();

    return res.json({ success: true, message: 'Password updated successfully' });
  } catch (err) {
    return next(err);
  }
}

async function refreshToken(req, res, next) {
  try {
    const { token } = req.body;
    if (!token) {
      throw new ApiError({
        statusCode: 401,
        message: AUTH_ERRORS.unauthorized.message,
        errorCode: 'AUTH_TOKEN_MISSING',
      });
    }

    const payload = jwt.verify(token, process.env.JWT_REFRESH_SECRET);
    const user = await User.findById(payload.sub);

    if (!user || !user.passwordHash) {
      throw new ApiError({
        statusCode: 401,
        message: AUTH_ERRORS.invalidCredentials.message,
        errorCode: AUTH_ERRORS.invalidCredentials.errorCode,
      });
    }

    if (user.passwordChangedAt && payload.iat * 1000 < new Date(user.passwordChangedAt).getTime()) {
      throw new ApiError({
        statusCode: 401,
        message: AUTH_ERRORS.invalidCredentials.message,
        errorCode: 'AUTH_TOKEN_REVOKED',
      });
    }

    const access = signToken(
      { sub: payload.sub, role: payload.role, deviceId: payload.deviceId },
      process.env.JWT_SECRET
    );

    return res.json({ access });
  } catch (err) {
    if (err instanceof jwt.TokenExpiredError) {
      logger.warn('Refresh token failed', { reason: 'TOKEN_EXPIRED', path: req.originalUrl, error: err.message });
      return next(
        new ApiError({
          statusCode: 401,
          message: AUTH_ERRORS.tokenExpired.message,
          errorCode: AUTH_ERRORS.tokenExpired.errorCode,
        })
      );
    }

    if (err instanceof jwt.JsonWebTokenError) {
      logger.warn('Refresh token failed', { reason: 'INVALID_SIGNATURE', path: req.originalUrl, error: err.message });
      return next(
        new ApiError({
          statusCode: 401,
          message: AUTH_ERRORS.invalidCredentials.message,
          errorCode: 'AUTH_INVALID_SIGNATURE',
        })
      );
    }

    logger.warn('Refresh token failed', { reason: 'REFRESH_FAILED', path: req.originalUrl, error: err.message });
    return next(
      new ApiError({
        statusCode: 401,
        message: AUTH_ERRORS.invalidCredentials.message,
        errorCode: 'AUTH_REFRESH_FAILED',
      })
    );
  }
}

module.exports = { anonymousLogin, register, login, forgotPassword, verifyOtp, resetPassword, refreshToken };
