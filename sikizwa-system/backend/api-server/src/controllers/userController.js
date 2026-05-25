const User = require('../models/User');
const logger = require('../config/logger');
const { ApiError } = require('../utils/ApiError');
const { buildSuccessResponse, requireField } = require('../utils/responseHelpers');

async function registerTrustedPendant(req, res, next) {
  try {
    const pendantId = requireField(req.body.pendantId, 'pendantId');
    const deviceType = typeof req.body.deviceType === 'string' && req.body.deviceType.trim().length > 0
      ? req.body.deviceType.trim()
      : 'pendant';
    const deviceName = typeof req.body.deviceName === 'string' ? req.body.deviceName.trim() : '';
    const now = new Date();

    const updatedUser = await User.findOneAndUpdate(
      {
        _id: req.user._id,
        'metadata.trustedPendants.pendantId': { $ne: pendantId },
      },
      {
        $push: {
          'metadata.trustedPendants': {
            pendantId,
            deviceType,
            deviceName,
            registeredAt: now,
            lastSeenAt: now,
          },
        },
      },
      { new: true, lean: true }
    );

    let trustedPendants = [];

    if (updatedUser) {
      trustedPendants = Array.isArray(updatedUser.metadata?.trustedPendants)
        ? updatedUser.metadata.trustedPendants
        : [];
      logger.info('Trusted pendant registered', {
        userId: req.user._id.toString(),
        pendantId,
        deviceType,
        deviceName,
      });
    } else {
      const touched = await User.findOneAndUpdate(
        { _id: req.user._id, 'metadata.trustedPendants.pendantId': pendantId },
        {
          $set: {
            'metadata.trustedPendants.$.deviceType': deviceType,
            'metadata.trustedPendants.$.deviceName': deviceName,
            'metadata.trustedPendants.$.lastSeenAt': now,
          },
        },
        { new: true, lean: true }
      );

      if (!touched) {
        throw new ApiError({
          statusCode: 500,
          message: 'Unable to register the trusted pendant at this time.',
          errorCode: 'PENDANT_REGISTRATION_FAILED',
        });
      }

      trustedPendants = Array.isArray(touched.metadata?.trustedPendants)
        ? touched.metadata.trustedPendants
        : [];
      logger.info('Trusted pendant refreshed lastSeenAt', {
        userId: req.user._id.toString(),
        pendantId,
      });
    }

    return res.json(buildSuccessResponse({ trustedPendants }, 'Trusted pendant synced successfully.'));
  } catch (err) {
    if (err instanceof ApiError) {
      logger.warn('Trusted pendant registration failed', {
        userId: req.user?._id?.toString(),
        error: err.message,
        pendantId: req.body?.pendantId,
      });
      return next(err);
    }

    logger.error('Trusted pendant registration unexpected error', {
      userId: req.user?._id?.toString(),
      error: err.message,
      stack: err.stack,
    });

    return next(err);
  }
}

module.exports = {
  registerTrustedPendant,
};
