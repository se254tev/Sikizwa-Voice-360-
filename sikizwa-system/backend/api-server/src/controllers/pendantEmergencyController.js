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

  if (fieldName === 'latitude' && (parsed < -90 || parsed > 90)) {
    throw invalid('latitude must be between -90 and 90');
  }

  if (fieldName === 'longitude' && (parsed < -180 || parsed > 180)) {
    throw invalid('longitude must be between -180 and 180');
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

function parseBatteryLevel(value) {
  if (value === undefined || value === null) {
    throw invalid('batteryLevel is required');
  }

  const parsed = Number(value);
  if (!Number.isFinite(parsed)) {
    throw invalid('batteryLevel must be a valid number');
  }

  if (parsed < 0 || parsed > 100) {
    throw invalid('batteryLevel must be between 0 and 100');
  }

  return parsed;
}

function parsePendantId(value) {
  if (typeof value !== 'string' || value.trim().length === 0) {
    throw invalid('pendantId is required');
  }

  return value.trim();
}

function broadcastDistressSignal(signal, isLiveUpdate = false) {
  const io = getSocket();
  if (!io) {
    return;
  }

  io.to('emergency-monitoring').emit('distress_signal', {
    id: signal._id,
    user_id: signal.user.toString(),
    lat: signal.lat,
    lng: signal.lng,
    timestamp: signal.timestamp,
    severity: signal.severity,
    status: signal.status,
    isLockedModeActive: signal.isLockedModeActive,
    source: signal.source,
    pendantId: signal.pendantId,
    batteryLevel: signal.batteryLevel,
    isLiveUpdate,
  });
}

function isTrustedPendant(user, pendantId) {
  const trustedPendants = Array.isArray(user?.metadata?.trustedPendants)
    ? user.metadata.trustedPendants
    : [];

  return trustedPendants.some((entry) => {
    if (!entry) {
      return false;
    }

    if (typeof entry === 'string') {
      return entry === pendantId;
    }

    return entry.pendantId === pendantId;
  });
}

async function createPendantSOS(req, res) {
  try {
    const { userId, pendantId, latitude, longitude, timestamp, batteryLevel } = req.body;

    if (typeof userId !== 'string' || !mongoose.Types.ObjectId.isValid(userId)) {
      throw new ApiError({ statusCode: 400, message: 'userId is required and must be a valid user id', errorCode: 'INVALID_USER_ID' });
    }

    if (userId !== req.user._id.toString()) {
      throw new ApiError({ statusCode: 403, message: 'userId does not match authenticated user', errorCode: 'USER_MISMATCH' });
    }

    const parsedPendantId = parsePendantId(pendantId);
    if (!isTrustedPendant(req.user, parsedPendantId)) {
      throw new ApiError({ statusCode: 403, message: 'trusted pendant validation failed', errorCode: 'PENDANT_NOT_TRUSTED' });
    }

    const parsedLat = parseCoordinate(latitude, 'latitude');
    const parsedLng = parseCoordinate(longitude, 'longitude');
    const parsedTimestamp = parseTimestamp(timestamp);
    const parsedBatteryLevel = parseBatteryLevel(batteryLevel);

    const recentSignal = await DistressSignal.findOne({
      user: req.user._id,
      pendantId: parsedPendantId,
      source: 'BLE_PENDANT',
      status: 'active',
      createdAt: { $gte: new Date(Date.now() - 15 * 1000) },
    }).sort({ createdAt: -1 });

    if (recentSignal) {
      return res.json(buildSuccessResponse({
        id: recentSignal._id,
        user_id: recentSignal.user.toString(),
        pendantId: recentSignal.pendantId,
        latitude: recentSignal.lat,
        longitude: recentSignal.lng,
        timestamp: recentSignal.timestamp,
        batteryLevel: recentSignal.batteryLevel,
        duplicate: true,
        status: recentSignal.status,
        source: recentSignal.source,
      }, 'Duplicate pendant SOS request suppressed.'));
    }

    const signal = await DistressSignal.create({
      user: req.user._id,
      lat: parsedLat,
      lng: parsedLng,
      timestamp: parsedTimestamp,
      status: 'active',
      severity: 'critical',
      isLockedModeActive: true,
      source: 'BLE_PENDANT',
      pendantId: parsedPendantId,
      batteryLevel: parsedBatteryLevel,
    });

    broadcastDistressSignal(signal);

    return res.status(201).json(buildSuccessResponse({
      id: signal._id,
      user_id: signal.user.toString(),
      pendantId: signal.pendantId,
      latitude: signal.lat,
      longitude: signal.lng,
      timestamp: signal.timestamp,
      batteryLevel: signal.batteryLevel,
      status: signal.status,
      source: signal.source,
    }, 'Pendant SOS created successfully.'));
  } catch (err) {
    if (err instanceof ApiError) {
      return res.status(err.statusCode || 400).json(buildFailureResponse({
        statusCode: err.statusCode || 400,
        message: err.message,
        errorCode: err.errorCode || 'PENDANT_EMERGENCY_ERROR',
      }));
    }

    console.error(err);
    return res.status(500).json(buildFailureResponse({
      statusCode: 500,
      message: 'Failed to process pendant SOS request',
      errorCode: 'PENDANT_EMERGENCY_FAILURE',
    }));
  }
}

async function updatePendantLocation(req, res) {
  try {
    const { userId, pendantId, latitude, longitude, timestamp } = req.body;

    if (typeof userId !== 'string' || !mongoose.Types.ObjectId.isValid(userId)) {
      throw new ApiError({ statusCode: 400, message: 'userId is required and must be a valid user id', errorCode: 'INVALID_USER_ID' });
    }

    if (userId !== req.user._id.toString()) {
      throw new ApiError({ statusCode: 403, message: 'userId does not match authenticated user', errorCode: 'USER_MISMATCH' });
    }

    const parsedPendantId = parsePendantId(pendantId);
    if (!isTrustedPendant(req.user, parsedPendantId)) {
      throw new ApiError({ statusCode: 403, message: 'trusted pendant validation failed', errorCode: 'PENDANT_NOT_TRUSTED' });
    }

    const parsedLat = parseCoordinate(latitude, 'latitude');
    const parsedLng = parseCoordinate(longitude, 'longitude');
    const parsedTimestamp = parseTimestamp(timestamp);

    let signal = await DistressSignal.findOne({
      user: req.user._id,
      pendantId: parsedPendantId,
      source: 'BLE_PENDANT',
      status: 'active',
    }).sort({ createdAt: -1 });

    if (!signal) {
      signal = await DistressSignal.create({
        user: req.user._id,
        lat: parsedLat,
        lng: parsedLng,
        timestamp: parsedTimestamp,
        status: 'active',
        severity: 'critical',
        isLockedModeActive: true,
        source: 'BLE_PENDANT',
        pendantId: parsedPendantId,
        batteryLevel: 100,
      });
    } else {
      signal.lat = parsedLat;
      signal.lng = parsedLng;
      signal.timestamp = parsedTimestamp;
      await signal.save();
    }

    broadcastDistressSignal(signal, true);

    return res.json(buildSuccessResponse({
      id: signal._id,
      user_id: signal.user.toString(),
      pendantId: signal.pendantId,
      latitude: signal.lat,
      longitude: signal.lng,
      timestamp: signal.timestamp,
      batteryLevel: signal.batteryLevel,
      status: signal.status,
      source: signal.source,
      liveUpdate: true,
    }, 'Pendant location updated successfully.'));
  } catch (err) {
    if (err instanceof ApiError) {
      return res.status(err.statusCode || 400).json(buildFailureResponse({
        statusCode: err.statusCode || 400,
        message: err.message,
        errorCode: err.errorCode || 'PENDANT_LOCATION_UPDATE_ERROR',
      }));
    }

    console.error(err);
    return res.status(500).json(buildFailureResponse({
      statusCode: 500,
      message: 'Failed to process pendant location update',
      errorCode: 'PENDANT_LOCATION_UPDATE_FAILURE',
    }));
  }
}

module.exports = { createPendantSOS, updatePendantLocation };
