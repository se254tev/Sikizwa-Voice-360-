const { getRedisClient, isRedisReady } = require('../config/redis');
const { ApiError } = require('../utils/apiError');
const logger = require('../config/logger');

function idempotencyMiddleware(ttlSeconds = 30) {
  return async (req, res, next) => {
    const requestId = typeof req.headers['x-request-id'] === 'string'
      ? req.headers['x-request-id'].trim()
      : '';

    if (!requestId) {
      return next();
    }

    const userId = req.user?._id?.toString() || 'anonymous';
    const key = `idempotency:${req.method}:${req.originalUrl}:${userId}:${requestId}`;
    const redisClient = getRedisClient();

    if (!isRedisReady() || !redisClient) {
      return next();
    }

    try {
      const acquired = await redisClient.set(key, 'locked', 'NX', 'EX', ttlSeconds);
      if (!acquired) {
        logger.warn('Duplicate request blocked by idempotency middleware', {
          userId,
          path: req.originalUrl,
          requestId,
        });
        throw new ApiError({
          statusCode: 409,
          message: 'Duplicate request detected. Please wait before retrying.',
          errorCode: 'DUPLICATE_REQUEST',
        });
      }
    } catch (error) {
      return next(error);
    }

    res.once('finish', async () => {
      if (res.statusCode >= 400) {
        try {
          await redisClient.del(key);
        } catch (err) {
          logger.warn('Unable to clear idempotency lock for failed request', {
            key,
            error: err.message,
          });
        }
      }
    });

    return next();
  };
}

module.exports = {
  idempotencyMiddleware,
};
