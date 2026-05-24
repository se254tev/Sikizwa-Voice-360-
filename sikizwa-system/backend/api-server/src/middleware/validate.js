const Joi = require('joi');

function validate(schema) {
  return (req, res, next) => {
    const { error } = schema.validate(
      {
        body: req.body,
      },
      { abortEarly: false, allowUnknown: true }
    );

    if (error) {
      return res.status(400).json({
        success: false,
        message: 'The request data is invalid. Please review the provided values and try again.',
        errorCode: 'VALIDATION_INVALID_PAYLOAD',
        details: error.details.map((detail) => detail.message),
      });
    }

    next();
  };
}

module.exports = validate;
