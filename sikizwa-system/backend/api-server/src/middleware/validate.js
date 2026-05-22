const Joi = require('joi');

function validate(schema) {
  return (req, res, next) => {
    const { error } = schema.validate({
      body: req.body,
      params: req.params,
      query: req.query
    }, { abortEarly: false, allowUnknown: false });

    if (error) {
      return res.status(400).json({ error: error.details.map((detail) => detail.message).join(', ') });
    }
    next();
  };
}

module.exports = validate;
