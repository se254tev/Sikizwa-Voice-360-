const Joi = require('joi');

const reportSchema = Joi.object({
  body: Joi.object({
    type: Joi.string().valid('gbv','depression','suicide','bullying','corruption','insecurity','drug','harassment').required(),
    description: Joi.string().max(2000).allow('', null),
    media: Joi.array().items(Joi.object({ url: Joi.string().uri(), type: Joi.string().required() })).optional(),
    location: Joi.object({ type: Joi.string().valid('Point').required(), coordinates: Joi.array().items(Joi.number()).length(2).required() }).optional()
  })
});

module.exports = { reportSchema };
