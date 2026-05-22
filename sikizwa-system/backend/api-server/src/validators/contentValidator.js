const Joi = require('joi');

const resourceSchema = Joi.object({
  body: Joi.object({
    title: Joi.string().max(200).required(),
    summary: Joi.string().max(1000).allow('', null),
    contentUrl: Joi.string().uri().allow('', null),
    media: Joi.array().items(Joi.object({ url: Joi.string().uri().required(), type: Joi.string().required() })).optional(),
    categories: Joi.array().items(Joi.string()).optional(),
    languages: Joi.array().items(Joi.string()).optional(),
    topic: Joi.string().max(100).optional(),
    description: Joi.string().max(1200).optional()
  })
});

module.exports = { resourceSchema };
