const Joi = require('joi');

const reportSchema = Joi.object({
  body: Joi.object({
    type: Joi.string()
      .valid('gbv','depression','suicide','bullying','corruption','insecurity','drug','harassment','support','general')
      .optional(),
    reportType: Joi.string().trim().min(2).max(60).optional(),
    incidentType: Joi.string().trim().min(2).max(120).optional(),
    title: Joi.string().trim().min(2).max(160).optional(),
    description: Joi.string().trim().min(10).max(2000).required(),
    media: Joi.array().items(Joi.object({ url: Joi.string().uri(), type: Joi.string().required() })).optional(),
    locationText: Joi.string().trim().max(200).optional(),
    location: Joi.alternatives().try(
      Joi.string().trim().max(200),
      Joi.object({
        type: Joi.string().valid('Point').optional(),
        coordinates: Joi.array().items(Joi.number()).length(2).optional(),
        address: Joi.string().trim().max(200).optional(),
      }).unknown(true)
    ).optional(),
    anonymousSubmission: Joi.boolean().optional(),
    timestamp: Joi.date().iso().optional(),
    priority: Joi.string().valid('low','medium','high').optional(),
    status: Joi.string().valid('pending','open','in-progress','resolved','closed','escalated').optional(),
  }).unknown(true),
});

module.exports = { reportSchema };
