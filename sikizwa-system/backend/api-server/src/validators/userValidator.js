const Joi = require('joi');

const trustedPendantSchema = Joi.object({
  body: Joi.object({
    pendantId: Joi.string().trim().min(1).required(),
    deviceType: Joi.string().trim().min(1).max(64).optional().allow(''),
    deviceName: Joi.string().trim().max(120).optional().allow(''),
  }).unknown(true),
});

module.exports = {
  trustedPendantSchema,
};
