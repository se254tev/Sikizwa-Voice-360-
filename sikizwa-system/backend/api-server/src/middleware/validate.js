const Joi = require('joi');

function validate(schema, options = {}) {
  const {
    includeDetails = true,
    failureMessage = 'The request data is invalid. Please review the provided values and try again.',
    failureCode = 'VALIDATION_INVALID_PAYLOAD',
    statusCode = 400,
  } = options;

  return (req, res, next) => {
    const { error } = schema.validate(
      {
        body: req.body,
      },
      { abortEarly: false, allowUnknown: true }
    );

    if (error) {
      const response = {
        success: false,
        message: failureMessage,
        errorCode: failureCode,
      };

      if (includeDetails) {
        response.details = error.details.map((detail) => detail.message);
      }

      return res.status(statusCode).json(response);
    }

    next();
  };
}

module.exports = validate;
