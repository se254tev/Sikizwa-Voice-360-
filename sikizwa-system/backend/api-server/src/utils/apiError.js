class ApiError extends Error {
  constructor({
    statusCode = 500,
    message,
    errorCode,
    details = null,
    isOperational = true,
  }) {
    super(message);

    this.statusCode = statusCode;
    this.errorCode = errorCode;
    this.isOperational = isOperational;
    this.details = details;
    this.name = this.constructor.name;

    Error.captureStackTrace(this, this.constructor);
  }
}

module.exports = {
  ApiError,
};
