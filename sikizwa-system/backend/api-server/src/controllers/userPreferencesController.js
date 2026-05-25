const User = require('../models/User');
const { normalizeUserPreferences, getUserPreferences } = require('../utils/settings');
const { buildSuccessResponse } = require('../utils/responseHelpers');
const { ApiError } = require('../utils/apiError');

async function getUserPreferencesHandler(req, res, next) {
  try {
    const preferences = getUserPreferences(req.user);
    res.json(buildSuccessResponse({ preferences }, 'User preferences loaded successfully.'));
  } catch (err) {
    next(err);
  }
}

async function patchUserPreferencesHandler(req, res, next) {
  try {
    if (!req.body || typeof req.body !== 'object') {
      throw new ApiError({ statusCode: 400, message: 'preferences payload is required', errorCode: 'VALIDATION_INVALID_PAYLOAD' });
    }

    const incoming = normalizeUserPreferences(req.body);
    const preferences = normalizeUserPreferences({
      notifications: {
        ...getUserPreferences(req.user).notifications,
        ...incoming.notifications,
      },
      privacy: {
        ...getUserPreferences(req.user).privacy,
        ...incoming.privacy,
      },
    });

    req.user.preferences = preferences;
    await req.user.save();

    res.json(buildSuccessResponse({ preferences }, 'User preferences updated successfully.'));
  } catch (err) {
    next(err);
  }
}

module.exports = {
  getUserPreferencesHandler,
  patchUserPreferencesHandler,
};
