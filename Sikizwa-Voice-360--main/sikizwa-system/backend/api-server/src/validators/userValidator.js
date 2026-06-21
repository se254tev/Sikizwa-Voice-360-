const Joi = require('joi');

const emergencyContactSchema = Joi.object({
  name: Joi.string().trim().min(1).max(120).required(),
  phone: Joi.string().trim().min(4).max(30).required(),
  relationship: Joi.string().trim().min(1).max(80).required(),
  type: Joi.string().trim().valid('personal', 'professional', 'guardian').optional().default('personal'),
});

const trustedPendantSchema = Joi.object({
  body: Joi.object({
    pendantId: Joi.string().trim().min(1).required(),
    deviceType: Joi.string().trim().min(1).max(64).optional().allow(''),
    deviceName: Joi.string().trim().max(120).optional().allow(''),
  }).unknown(true),
});

const emergencyContactsSchema = Joi.object({
  body: Joi.object({
    contacts: Joi.array().items(emergencyContactSchema).max(3).required(),
  }).unknown(true),
});

module.exports = {
  trustedPendantSchema,
  emergencyContactsSchema,
};
