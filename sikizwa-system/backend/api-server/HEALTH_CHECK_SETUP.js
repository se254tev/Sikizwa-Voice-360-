/**
 * OPTIONAL: Example of how to add health check endpoints to your Express app
 * 
 * To use this, add the following to src/app.js or create a new routes/health.js file:
 * 
 * const { getApplicationHealth, pingRedis } = require('./utils/healthCheck');
 * 
 * // Detailed health check
 * app.get('/health', (req, res) => {
 *   res.json(getApplicationHealth());
 * });
 * 
 * // Redis-specific health check
 * app.get('/health/redis', async (req, res) => {
 *   const result = await pingRedis();
 *   const statusCode = result.success ? 200 : 503;
 *   res.status(statusCode).json(result);
 * });
 */

// Example health check middleware for logging
const logger = require('./logger');

function healthCheckMiddleware(req, res, next) {
  const start = Date.now();
  res.on('finish', () => {
    const duration = Date.now() - start;
    logger.debug(`Health check - Status: ${res.statusCode}, Duration: ${duration}ms`);
  });
  next();
}

module.exports = {
  healthCheckMiddleware,
};
