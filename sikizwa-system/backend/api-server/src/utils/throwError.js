const { ApiError } = require('./apiError');

function throwError({
  statusCode = 500,
  message,
  errorCode,
  details = null,
}) {
  throw new ApiError({
    statusCode,
    message,
    errorCode,
    details,
  });
}

module.exports = {
  throwError,
};
