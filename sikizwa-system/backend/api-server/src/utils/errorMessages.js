const AUTH_ERRORS = {
  invalidCredentials: {
    message: 'Invalid email or password.',
    errorCode: 'AUTH_INVALID_CREDENTIALS',
  },
  tokenExpired: {
    message: 'Your session has expired. Please sign in again.',
    errorCode: 'AUTH_TOKEN_EXPIRED',
  },
  unauthorized: {
    message: 'Authentication is required to access this resource.',
    errorCode: 'AUTH_REQUIRED',
  },
  forbidden: {
    message: 'Access denied. You do not have permission to perform this action.',
    errorCode: 'FORBIDDEN_ACCESS',
  },
};

const VALIDATION_ERRORS = {
  missingFields: {
    message: 'Required fields are missing. Please review your request and try again.',
    errorCode: 'VALIDATION_MISSING_FIELDS',
  },
  invalidPayload: {
    message: 'The request data is invalid. Please review the provided values and try again.',
    errorCode: 'VALIDATION_INVALID_PAYLOAD',
  },
  invalidFormat: {
    message: 'One or more fields have an invalid format.',
    errorCode: 'VALIDATION_INVALID_FORMAT',
  },
};

const NOT_FOUND_ERRORS = {
  resourceNotFound: {
    message: 'Resource not found.',
    errorCode: 'RESOURCE_NOT_FOUND',
  },
  routeNotFound: {
    message: 'The requested endpoint could not be found.',
    errorCode: 'ROUTE_NOT_FOUND',
  },
};

const SERVER_ERRORS = {
  internalServerError: {
    message: 'Something went wrong on our side. Please try again later.',
    errorCode: 'SERVER_INTERNAL_ERROR',
  },
  unexpectedError: {
    message: 'An unexpected error occurred while processing your request.',
    errorCode: 'SERVER_UNEXPECTED_ERROR',
  },
};

const NETWORK_ERRORS = {
  corsBlocked: {
    message: 'The request was blocked by the browser security policy. Please check the application origin and try again.',
    errorCode: 'NETWORK_CORS_BLOCKED',
  },
  requestFailed: {
    message: 'The network request could not be completed. Please try again in a moment.',
    errorCode: 'NETWORK_REQUEST_FAILED',
  },
  timeout: {
    message: 'The request timed out. Please try again.',
    errorCode: 'NETWORK_TIMEOUT',
  },
};

const DB_ERRORS = {
  connectionFailed: {
    message: 'The database is currently unavailable. Please try again later.',
    errorCode: 'DB_CONNECTION_FAILED',
  },
  queryFailed: {
    message: 'The database request could not be completed. Please try again later.',
    errorCode: 'DB_QUERY_FAILED',
  },
  recordConflict: {
    message: 'This request conflicts with existing data. Please review your input and try again.',
    errorCode: 'DB_RECORD_CONFLICT',
  },
};

const RATE_LIMIT_ERRORS = {
  tooManyRequests: {
    message: 'Too many requests have been made in a short period. Please wait a moment and try again.',
    errorCode: 'RATE_LIMIT_EXCEEDED',
  },
};

const CORS_ERRORS = {
  originNotAllowed: {
    message: 'This origin is not allowed to access the API.',
    errorCode: 'CORS_ORIGIN_NOT_ALLOWED',
  },
};

module.exports = {
  AUTH_ERRORS,
  VALIDATION_ERRORS,
  NOT_FOUND_ERRORS,
  SERVER_ERRORS,
  NETWORK_ERRORS,
  DB_ERRORS,
  RATE_LIMIT_ERRORS,
  CORS_ERRORS,
};
