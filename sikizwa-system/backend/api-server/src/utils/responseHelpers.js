const { ApiError } = require('./apiError');
const { AUTH_ERRORS } = require('./errorMessages');

function buildSuccessResponse(data = {}, message = 'Request completed successfully') {
  return {
    success: true,
    message,
    data,
  };
}

function buildFailureResponse({ statusCode = 500, message = 'An error occurred', errorCode = 'SERVER_INTERNAL_ERROR', details = null }) {
  const response = {
    success: false,
    message,
    errorCode,
  };

  if (details) {
    response.details = details;
  }

  return response;
}

function buildSecurityFailureResponse({
  statusCode = 401,
  message = AUTH_ERRORS.unauthorized.message,
  errorCode = AUTH_ERRORS.unauthorized.errorCode,
  details = null,
}) {
  return buildFailureResponse({ statusCode, message, errorCode, details });
}

function requireField(value, fieldName) {
  if (typeof value !== 'string' || value.trim().length === 0) {
    throw new ApiError({ statusCode: 400, message: `${fieldName} is required`, errorCode: 'VALIDATION_INVALID_PAYLOAD' });
  }

  return value.trim();
}

module.exports = {
  buildSuccessResponse,
  buildFailureResponse,
  buildSecurityFailureResponse,
  requireField,
};
