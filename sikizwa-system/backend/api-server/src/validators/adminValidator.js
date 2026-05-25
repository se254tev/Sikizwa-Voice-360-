const Joi = require('joi');

const adminSignupSchema = Joi.object({
  body: Joi.object({
    fullName: Joi.string().trim().min(2).max(120).required(),
    phoneNumber: Joi.string().trim().pattern(/^\+?[0-9]{7,15}$/).required(),
    email: Joi.string().trim().email().required(),
    nationalId: Joi.string().trim().min(5).max(30).required(),
    password: Joi.string().min(8).max(128).required(),
    confirmPassword: Joi.any().valid(Joi.ref('password')).required().messages({
      'any.only': 'confirm password must match password',
    }),
  }).unknown(true),
});

const adminLoginSchema = Joi.object({
  body: Joi.object({
    identifier: Joi.string().trim().min(3).max(128).required(),
    password: Joi.string().min(8).required(),
  }).unknown(true),
});

const reportStatusSchema = Joi.object({
  body: Joi.object({
    status: Joi.string().valid('pending','open','in-progress','resolved','closed','escalated').required(),
  }).unknown(true),
});

module.exports = { adminSignupSchema, adminLoginSchema, reportStatusSchema };