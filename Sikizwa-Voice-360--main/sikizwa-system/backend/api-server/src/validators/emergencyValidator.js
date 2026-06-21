const Joi = require('joi');

const emergencySchema = Joi.object({
  body: Joi.object({
    location: Joi.object({ type: Joi.string().valid('Point').required(), coordinates: Joi.array().items(Joi.number()).length(2).required() }).required(),
    notes: Joi.string().max(1500).allow('', null),
    trustedContacts: Joi.array().items(Joi.string()).max(10).optional(),
    panic: Joi.boolean().optional()
  })
});

module.exports = { emergencySchema };
