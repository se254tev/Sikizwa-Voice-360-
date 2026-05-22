const Joi = require('joi');

const registerSchema = Joi.object({
  body: Joi.object({
    username: Joi.string().min(3).max(64).required(),
    password: Joi.string().min(8).required(),
    role: Joi.string().valid('user', 'counsellor', 'admin', 'responder').default('user')
  })
});

const loginSchema = Joi.object({
  body: Joi.object({
    username: Joi.string().min(3).max(64).required(),
    password: Joi.string().min(8).required()
  })
});

const refreshSchema = Joi.object({
  body: Joi.object({
    token: Joi.string().required()
  })
});

module.exports = { registerSchema, loginSchema, refreshSchema };
