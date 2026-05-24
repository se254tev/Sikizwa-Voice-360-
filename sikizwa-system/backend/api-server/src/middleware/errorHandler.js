const logger = require('../config/logger');
const { ApiError } = require('../utils/apiError');
const {
  AUTH_ERRORS,
  VALIDATION_ERRORS,
  NOT_FOUND_ERRORS,
  SERVER_ERRORS,
  NETWORK_ERRORS,
  DB_ERRORS,
  RATE_LIMIT_ERRORS,
  CORS_ERRORS,
} = require('../utils/errorMessages');

function getStandardError(err) {
  if (err instanceof ApiError) {
    return {
      statusCode: err.statusCode,
      message: err.message,
      errorCode: err.errorCode,
      details: err.details,
    };
  }

  if (err.message === 'Not allowed by CORS') {
    return {
      statusCode: 403,
      message: CORS_ERRORS.originNotAllowed.message,
      errorCode: CORS_ERRORS.originNotAllowed.errorCode,
    };
  }

  if (err.statusCode === 401) {
    return {
      statusCode: 401,
      message: AUTH_ERRORS.unauthorized.message,
      errorCode: AUTH_ERRORS.unauthorized.errorCode,
    };
  }

  if (err.statusCode === 403) {
    return {
      statusCode: 403,
      message: AUTH_ERRORS.forbidden.message,
      errorCode: AUTH_ERRORS.forbidden.errorCode,
    };
  }

  if (err.statusCode === 404) {
    return {
      statusCode: 404,
      message: NOT_FOUND_ERRORS.resourceNotFound.message,
      errorCode: NOT_FOUND_ERRORS.resourceNotFound.errorCode,
    };
  }

  if (err.statusCode === 429) {
    return {
      statusCode: 429,
      message: RATE_LIMIT_ERRORS.tooManyRequests.message,
      errorCode: RATE_LIMIT_ERRORS.tooManyRequests.errorCode,
    };
  }

  if (err.name === 'ValidationError' || /validation/i.test(err.message)) {
    return {
      statusCode: 400,
      message: VALIDATION_ERRORS.invalidPayload.message,
      errorCode: VALIDATION_ERRORS.invalidPayload.errorCode,
    };
  }

  if (
    err.code === 11000 ||
    err.code === 'ER_DUP_ENTRY' ||
    /duplicate key|already exists/i.test(err.message)
  ) {
    return {
      statusCode: 409,
      message: DB_ERRORS.recordConflict.message,
      errorCode: DB_ERRORS.recordConflict.errorCode,
    };
  }

  if (
    /ECONNREFUSED|ECONNRESET|ETIMEDOUT|MongoNetworkError|MongooseServerSelectionError/i.test(
      err.message
    )
  ) {
    return {
      statusCode: 503,
      message: DB_ERRORS.connectionFailed.message,
      errorCode: DB_ERRORS.connectionFailed.errorCode,
    };
  }

  if (/(token|jwt|unauthorized|invalid credentials)/i.test(err.message)) {
    return {
      statusCode: 401,
      message: AUTH_ERRORS.invalidCredentials.message,
      errorCode: AUTH_ERRORS.invalidCredentials.errorCode,
    };
  }

  if (/forbidden|permission|access denied/i.test(err.message)) {
    return {
      statusCode: 403,
      message: AUTH_ERRORS.forbidden.message,
      errorCode: AUTH_ERRORS.forbidden.errorCode,
    };
  }

  if (/network|fetch failed|request failed|socket hang up/i.test(err.message)) {
    return {
      statusCode: 502,
      message: NETWORK_ERRORS.requestFailed.message,
      errorCode: NETWORK_ERRORS.requestFailed.errorCode,
    };
  }

  return {
    statusCode: 500,
    message: SERVER_ERRORS.internalServerError.message,
    errorCode: SERVER_ERRORS.internalServerError.errorCode,
  };
}

function errorHandler(err, req, res, next) {
  const normalizedError = getStandardError(err);
  const isProduction = process.env.NODE_ENV === 'production';

  logger.error(
    {
      errorCode: normalizedError.errorCode,
      statusCode: normalizedError.statusCode,
      message: normalizedError.message,
      method: req.method,
      path: req.originalUrl,
      stack: isProduction ? undefined : err.stack,
      details: normalizedError.details,
    },
    'Request failed'
  );

  const response = {
    success: false,
    message: normalizedError.message,
    errorCode: normalizedError.errorCode,
  };

  if (!isProduction && normalizedError.details) {
    response.details = normalizedError.details;
  }

  if (!isProduction && err.stack) {
    response.stack = err.stack;
  }

  res.status(normalizedError.statusCode).json(response);
}

module.exports = errorHandler;
