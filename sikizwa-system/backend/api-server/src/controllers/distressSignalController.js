const mongoose = require('mongoose');
const DistressSignal = require('../models/DistressSignal');
const { getSocket } = require('../utils/socketRegistry');
const { buildSuccessResponse, buildFailureResponse } = require('../utils/responseHelpers');
const { ApiError } = require('../utils/ApiError');

function invalid(message, status = 400) {
  const error = new Error(message);
  error.status = status;
  return error;
}

function parseCoordinate(value, fieldName) {
  if (value === undefined || value === null || value === '') {
    throw invalid(`${fieldName} is required`);
  }

  const parsed = Number(value);
  if (!Number.isFinite(parsed)) {
    throw invalid(`${fieldName} must be a valid number`);
  }

  if (fieldName === 'lat' && (parsed < -90 || parsed > 90)) {
    throw invalid('lat must be between -90 and 90');
  }

  if (fieldName === 'lng' && (parsed < -180 || parsed > 180)) {
    throw invalid('lng must be between -180 and 180');
  }

  return parsed;
}

function parseTimestamp(value) {
  if (typeof value !== 'string' || value.trim().length === 0) {
    throw invalid('timestamp is required');
  }

  const parsed = new Date(value);
  if (Number.isNaN(parsed.getTime())) {
    throw invalid('timestamp must be a valid ISO 8601 date');
  }

  if (parsed.getTime() > Date.now() + 5 * 60 * 1000) {
    throw invalid('timestamp cannot be in the future');
  }

  return parsed;
}

async function createDistressSignal(req, res) {
  try {
    const { user_id, lat, lng, timestamp, message } = req.body;

    if (typeof user_id !== 'string' || !mongoose.Types.ObjectId.isValid(user_id)) {
      throw new ApiError({ statusCode: 400, message: 'user_id is required and must be a valid user id', errorCode: 'INVALID_USER_ID' });
    }

    if (user_id !== req.user._id.toString()) {
      throw new ApiError({ statusCode: 403, message: 'user_id does not match authenticated user', errorCode: 'USER_MISMATCH' });
    }

    const parsedLat = parseCoordinate(lat, 'lat');
    const parsedLng = parseCoordinate(lng, 'lng');
    const parsedTimestamp = parseTimestamp(timestamp);

    let parsedMessage;
    if (message !== undefined) {
      if (typeof message !== 'string') {
        throw new ApiError({ statusCode: 400, message: 'message must be a string', errorCode: 'INVALID_MESSAGE_TYPE' });
      }

      parsedMessage = message.trim();
      if (parsedMessage.length > 500) {
        throw new ApiError({ statusCode: 400, message: 'message must be 500 characters or fewer', errorCode: 'MESSAGE_TOO_LONG' });
      }
    }

    const signal = await DistressSignal.create({
      user: req.user._id,
      lat: parsedLat,
      lng: parsedLng,
      timestamp: parsedTimestamp,
      message: parsedMessage,
      status: 'active',
      severity: 'critical',
      isLockedModeActive: true,
    });

    const io = getSocket();
    if (io) {
      io.to('emergency-monitoring').emit('distress_signal', {
        id: signal._id,
        user_id: signal.user.toString(),
        lat: signal.lat,
        lng: signal.lng,
        timestamp: signal.timestamp,
        severity: signal.severity,
        status: signal.status,
        isLockedModeActive: signal.isLockedModeActive,
      });
    }

    return res.status(201).json(buildSuccessResponse({
      id: signal._id,
      user_id: signal.user.toString(),
      lat: signal.lat,
      lng: signal.lng,
      timestamp: signal.timestamp,
      status: signal.status,
      severity: signal.severity,
      isLockedModeActive: signal.isLockedModeActive,
    }, 'Distress signal created successfully.'));
  } catch (err) {
    if (err instanceof ApiError) {
      return res.status(err.statusCode || 400).json(buildFailureResponse({
        statusCode: err.statusCode || 400,
        message: err.message,
        errorCode: err.errorCode || 'DISTRESS_SIGNAL_ERROR',
      }));
    }

    console.error(err);
    return res.status(500).json(buildFailureResponse({
      statusCode: 500,
      message: 'Failed to create distress signal',
      errorCode: 'DISTRESS_SIGNAL_FAILURE',
    }));
  }
}

async function listDistressSignals(req, res) {
  try {
    const signals = await DistressSignal.find({ status: 'active' })
      .populate('user', 'username role fullName phone name')
      .sort({ timestamp: -1 })
      .limit(100);

    return res.json(buildSuccessResponse({
      signals: signals.map((signal) => ({
        id: signal._id,
        user: {
          id: signal.user?._id ? signal.user._id.toString() : null,
          username: signal.user?.username || null,
          fullName: signal.user?.fullName || signal.user?.name || null,
          phone: signal.user?.phone || null,
          role: signal.user?.role || null,
        },
        lat: signal.lat,
        lng: signal.lng,
        timestamp: signal.timestamp,
        status: signal.status,
        severity: signal.severity,
        isLockedModeActive: signal.isLockedModeActive,
      })),
    }, 'Distress signals loaded successfully.'));
  } catch (err) {
    console.error(err);
    return res.status(500).json(buildFailureResponse({
      statusCode: 500,
      message: 'Failed to load distress signals',
      errorCode: 'DISTRESS_SIGNALS_LOAD_FAILED',
    }));
  }
}

module.exports = { createDistressSignal, listDistressSignals };
