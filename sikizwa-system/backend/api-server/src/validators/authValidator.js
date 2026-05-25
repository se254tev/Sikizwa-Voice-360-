const Joi = require('joi');

const registerSchema = Joi.object({
  body: Joi.object({
    fullName: Joi.string().min(2).max(120).required(),
    phone: Joi.string().pattern(/^\+?[0-9]{7,15}$/).required(),
    password: Joi.string().min(8).required(),
    email: Joi.string().email().optional().allow(''),
    role: Joi.string().valid('user', 'counsellor', 'admin', 'super_admin', 'responder', 'other').default('other'),
    emergencyContacts: Joi.array().items(
      Joi.object({
        name: Joi.string().min(2).required(),
        phone: Joi.string().pattern(/^\+?[0-9]{7,15}$/).required(),
        relationship: Joi.string().min(2).required(),
        type: Joi.string().valid('personal', 'professional', 'guardian').default('personal'),
      })
    ).min(1).required(),
    bloodGroup: Joi.string().max(10).optional().allow(''),
    allergies: Joi.string().max(240).optional().allow(''),
    medicalConditions: Joi.string().max(240).optional().allow(''),
    location: Joi.string().max(120).optional().allow(''),
    device_id: Joi.string().optional().allow(''),
    device_type: Joi.string().valid('phone', 'tablet', 'tv', 'watch').optional().allow(''),
  }).unknown(true),
});

const loginSchema = Joi.object({
  body: Joi.object({
    identifier: Joi.string().min(3).max(128).required(),
    password: Joi.string().min(8).required(),
    device_id: Joi.string().optional().allow(''),
    device_type: Joi.string().valid('phone', 'tablet', 'tv', 'watch').optional().allow(''),
  }).unknown(true),
});

const refreshSchema = Joi.object({
  body: Joi.object({
    token: Joi.string().required(),
  }),
});

module.exports = { registerSchema, loginSchema, refreshSchema };
