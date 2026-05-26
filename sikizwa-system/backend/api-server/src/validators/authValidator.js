const Joi = require('joi');

const passwordPattern = /^(?=.*[A-Za-z])(?=.*\d).{8,}$/;

const registerSchema = Joi.object({
  body: Joi.object({
    fullName: Joi.string().trim().min(2).max(120).required(),
    phone: Joi.string().trim().pattern(/^\+?[0-9]{7,15}$/).required(),
    password: Joi.string().trim().min(8).pattern(passwordPattern).required(),
    role: Joi.string().valid('user', 'counsellor', 'admin', 'super_admin', 'responder', 'other').default('other'),
    device_id: Joi.string().trim().optional().allow(''),
    device_type: Joi.string().valid('phone', 'tablet', 'tv', 'watch').optional().allow(''),
  }).unknown(false),
});

const loginSchema = Joi.object({
  body: Joi.object({
    identifier: Joi.string().trim().pattern(/^\+?[0-9]{7,15}$/).required(),
    password: Joi.string().trim().min(8).required(),
    device_id: Joi.string().trim().optional().allow(''),
    device_type: Joi.string().valid('phone', 'tablet', 'tv', 'watch').optional().allow(''),
  }).unknown(false),
});

const forgotPasswordSchema = Joi.object({
  body: Joi.object({
    phone: Joi.string().trim().pattern(/^\+?[0-9]{7,15}$/).required(),
  }).unknown(false),
});

const verifyOtpSchema = Joi.object({
  body: Joi.object({
    phone: Joi.string().trim().pattern(/^\+?[0-9]{7,15}$/).required(),
    otp: Joi.string().trim().pattern(/^\d{6}$/).required(),
  }).unknown(false),
});

const resetPasswordSchema = Joi.object({
  body: Joi.object({
    phone: Joi.string().trim().pattern(/^\+?[0-9]{7,15}$/).required(),
    otp: Joi.string().trim().pattern(/^\d{6}$/).required(),
    password: Joi.string().trim().min(8).pattern(passwordPattern).required(),
  }).unknown(false),
});

const refreshSchema = Joi.object({
  body: Joi.object({
    token: Joi.string().required(),
  }).unknown(false),
});

module.exports = { registerSchema, loginSchema, forgotPasswordSchema, verifyOtpSchema, resetPasswordSchema, refreshSchema };
