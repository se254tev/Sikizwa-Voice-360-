const rateLimit = require('express-rate-limit');
const { buildFailureResponse } = require('../utils/responseHelpers');

function createRateLimiter(options) {
  return rateLimit({
    windowMs: options.windowMs,
    max: options.max,
    standardHeaders: true,
    legacyHeaders: false,
    handler: (req, res) => {
      res.status(429).json(
        buildFailureResponse({
          statusCode: 429,
          message: 'Too many requests have been made in a short period. Please try again later.',
          errorCode: 'RATE_LIMIT_EXCEEDED',
        })
      );
    },
  });
}

const authLoginLimiter = createRateLimiter({ windowMs: 15 * 60 * 1000, max: 10 });
const emergencyLimiter = createRateLimiter({ windowMs: 60 * 1000, max: 8 });
const aiLimiter = createRateLimiter({ windowMs: 60 * 1000, max: 20 });
const reportLimiter = createRateLimiter({ windowMs: 60 * 1000, max: 12 });

module.exports = {
  authLoginLimiter,
  emergencyLimiter,
  aiLimiter,
  reportLimiter,
};
