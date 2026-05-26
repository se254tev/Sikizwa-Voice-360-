const User = require('../models/User');
const logger = require('../config/logger');
const { ApiError } = require('../utils/apiError');
const { buildSuccessResponse, requireField } = require('../utils/responseHelpers');

function normalizeEmergencyContacts(contacts) {
  if (!Array.isArray(contacts)) {
    return [];
  }

  return contacts.map((contact) => {
    if (!contact || typeof contact !== 'object') {
      throw new ApiError({
        statusCode: 400,
        message: 'Each emergency contact must include a name, phone number, and relationship.',
        errorCode: 'VALIDATION_INVALID_PAYLOAD',
      });
    }

    const name = typeof contact.name === 'string' ? contact.name.trim() : '';
    const phone = typeof contact.phone === 'string' ? contact.phone.trim() : '';
    const relationship = typeof contact.relationship === 'string' ? contact.relationship.trim() : '';
    const type = typeof contact.type === 'string' ? contact.type.trim().toLowerCase() : 'personal';

    if (!name || !phone || !relationship) {
      throw new ApiError({
        statusCode: 400,
        message: 'Each emergency contact must include a name, phone number, and relationship.',
        errorCode: 'VALIDATION_INVALID_PAYLOAD',
      });
    }

    if (!['personal', 'professional', 'guardian'].includes(type)) {
      throw new ApiError({
        statusCode: 400,
        message: 'Each emergency contact type must be personal, professional, or guardian.',
        errorCode: 'VALIDATION_INVALID_PAYLOAD',
      });
    }

    return {
      name,
      phone,
      relationship,
      type,
    };
  });
}

async function getEmergencyContacts(req, res) {
  const currentUser = await User.findById(req.user._id).select('emergencyContacts');
  const contacts = Array.isArray(currentUser?.emergencyContacts) ? currentUser.emergencyContacts : [];

  return res.json(buildSuccessResponse({ contacts }, 'Emergency contacts loaded successfully.'));
}

async function saveEmergencyContacts(req, res, next) {
  try {
    const contacts = normalizeEmergencyContacts(req.body.contacts);

    const updatedUser = await User.findByIdAndUpdate(
      req.user._id,
      { $set: { emergencyContacts: contacts } },
      { new: true, lean: true }
    );

    if (!updatedUser) {
      throw new ApiError({
        statusCode: 500,
        message: 'Unable to save emergency contacts at this time.',
        errorCode: 'EMERGENCY_CONTACTS_UPDATE_FAILED',
      });
    }

    logger.info('Emergency contacts saved', {
      userId: req.user._id.toString(),
      contactCount: contacts.length,
    });

    return res.json(buildSuccessResponse({ contacts: updatedUser.emergencyContacts || [] }, 'Emergency contacts saved successfully.'));
  } catch (err) {
    if (err instanceof ApiError) {
      logger.warn('Emergency contacts update failed', {
        userId: req.user?._id?.toString(),
        error: err.message,
      });
      return next(err);
    }

    logger.error('Emergency contacts update unexpected error', {
      userId: req.user?._id?.toString(),
      error: err.message,
      stack: err.stack,
    });

    return next(err);
  }
}

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
  getEmergencyContacts,
  saveEmergencyContacts,
  registerTrustedPendant,
};
