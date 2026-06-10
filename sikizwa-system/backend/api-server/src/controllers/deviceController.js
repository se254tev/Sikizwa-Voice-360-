const jwt = require('jsonwebtoken');
const bcrypt = require('bcrypt');
const { ApiError } = require('../utils/apiError');
const { AUTH_ERRORS, VALIDATION_ERRORS, NOT_FOUND_ERRORS, SERVER_ERRORS } = require('../utils/errorMessages');
const User = require('../models/User');
const Device = require('../models/Device');

function signToken(payload, secret, expiresIn = '15m') {
  return jwt.sign(payload, secret, { expiresIn });
}

function throwValidationError(message, errorCode = VALIDATION_ERRORS.invalidPayload.errorCode) {
  throw new ApiError({ statusCode: 400, message, errorCode });
}

function parsePhone(value) {
  if (typeof value !== 'string') {
    throwValidationError('phone is required');
  }

  const normalized = value.trim();
  if (!/^\+?[0-9]{7,15}$/.test(normalized)) {
    throwValidationError('phone must be a valid international number', VALIDATION_ERRORS.invalidFormat.errorCode);
  }

  return normalized;
}

function parseDeviceType(value) {
  if (!['phone', 'tablet', 'tv', 'watch'].includes(value)) {
    throwValidationError('device_type must be phone, tablet, tv, or watch', VALIDATION_ERRORS.invalidFormat.errorCode);
  }

  return value;
}

function parseDeviceId(value) {
  if (typeof value !== 'string' || value.trim().length === 0) {
    throwValidationError('device_id is required');
  }

  return value.trim();
}

async function authenticateUser(phone, password) {
  const user = await User.findOne({ $or: [{ phone }, { username: phone }] });
  if (!user) {
    throw new ApiError({
      statusCode: 401,
      message: AUTH_ERRORS.invalidCredentials.message,
      errorCode: AUTH_ERRORS.invalidCredentials.errorCode,
    });
  }

  const ok = await bcrypt.compare(password, user.passwordHash || '');
  if (!ok) {
    throw new ApiError({
      statusCode: 401,
      message: AUTH_ERRORS.invalidCredentials.message,
      errorCode: AUTH_ERRORS.invalidCredentials.errorCode,
    });
  }

  return user;
}

async function issuePairingCode(req, res, next) {
  try {
    const deviceId = parseDeviceId(req.body.device_id);
    const deviceType = parseDeviceType(req.body.device_type);

    const payload = {
      deviceId,
      deviceType,
      purpose: 'device-link',
    };

    const pairingCode = jwt.sign(payload, process.env.JWT_SECRET, { expiresIn: '10m' });

    return res.json({
      deviceId,
      deviceType,
      pairingCode,
      expiresAt: new Date(Date.now() + 10 * 60 * 1000).toISOString(),
    });
  } catch (err) {
    return next(err);
  }
}

async function linkDevice(req, res, next) {
  try {
    const deviceId = parseDeviceId(req.body.device_id);
    const deviceType = parseDeviceType(req.body.device_type);
    const pairingCode = typeof req.body.pairing_code === 'string' ? req.body.pairing_code.trim() : '';

    if (!pairingCode) {
      throwValidationError('pairing_code is required');
    }

    let parsedPairing;
    try {
      parsedPairing = jwt.verify(pairingCode, process.env.JWT_SECRET);
    } catch (err) {
      throw new ApiError({
        statusCode: 400,
        message: 'invalid pairing code',
        errorCode: VALIDATION_ERRORS.invalidPayload.errorCode,
      });
    }

    if (parsedPairing.purpose !== 'device-link') {
      throw new ApiError({
        statusCode: 400,
        message: 'invalid pairing code',
        errorCode: VALIDATION_ERRORS.invalidPayload.errorCode,
      });
    }

    if (parsedPairing.deviceId !== deviceId || parsedPairing.deviceType !== deviceType) {
      throw new ApiError({
        statusCode: 400,
        message: 'pairing code does not match device',
        errorCode: VALIDATION_ERRORS.invalidPayload.errorCode,
      });
    }

    const phone = parsePhone(req.body.phone);
    const password = typeof req.body.password === 'string' ? req.body.password : '';

    if (!password) {
      throwValidationError('password is required');
    }

    const user = await authenticateUser(phone, password);

    await Device.findOneAndUpdate(
      { deviceId },
      {
        userId: user._id,
        deviceId,
        deviceType,
        pairedAt: new Date(),
        isPrimary: false,
        isActive: true,
      },
      { upsert: true, new: true }
    );

    const access = signToken({ sub: user._id, role: user.role }, process.env.JWT_SECRET);
    const refresh = signToken({ sub: user._id }, process.env.JWT_REFRESH_SECRET, '30d');

    return res.json({
      access,
      refresh,
      device: {
        deviceId,
        deviceType,
        pairedAt: new Date().toISOString(),
        isPrimary: false,
      },
      user: {
        id: user._id,
        name: user.name,
        phone: user.phone,
        role: user.role,
      },
    });
  } catch (err) {
    return next(err);
  }
}

async function logoutDevice(req, res, next) {
  try {
    if (!req.body.device_id || typeof req.body.device_id !== 'string') {
      throwValidationError('device_id is required');
    }

    const device = await Device.findOneAndUpdate(
      { deviceId: req.body.device_id },
      { isActive: false },
      { new: true }
    );

    if (!device) {
      throw new ApiError({
        statusCode: 404,
        message: NOT_FOUND_ERRORS.resourceNotFound.message,
        errorCode: NOT_FOUND_ERRORS.resourceNotFound.errorCode,
      });
    }

    return res.json({ ok: true, deviceId: device.deviceId, isActive: false });
  } catch (err) {
    if (err instanceof ApiError) {
      return next(err);
    }

    return next(
      new ApiError({
        statusCode: 500,
        message: SERVER_ERRORS.internalServerError.message,
        errorCode: SERVER_ERRORS.internalServerError.errorCode,
      })
    );
  }
}

module.exports = { issuePairingCode, linkDevice, logoutDevice };
