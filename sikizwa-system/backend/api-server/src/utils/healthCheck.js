const { getRedisClient, isRedisReady } = require('../config/redis');

/**
 * Health check utilities for Redis and application status
 */

/**
 * Get Redis health status
 * @returns {Object} Redis health status
 */
function getRedisHealth() {
  const redisClient = getRedisClient();
  
  if (!redisClient) {
    return {
      status: 'disabled',
      message: 'Redis is not configured',
      ready: false,
    };
  }

  return {
    status: redisClient.status,
    ready: isRedisReady(),
    connected: redisClient.connected,
    connecting: redisClient.connecting,
    message: `Redis connection status: ${redisClient.status}`,
    connectedTime: redisClient.connectedTime || null,
  };
}

/**
 * Ping Redis to check connectivity
 * @returns {Promise<Object>} Ping result
 */
async function pingRedis() {
  const redisClient = getRedisClient();
  
  if (!redisClient) {
    return {
      success: false,
      message: 'Redis client not available',
    };
  }

  try {
    const result = await redisClient.ping();
    return {
      success: true,
      message: `Redis ping successful: ${result}`,
      timestamp: new Date().toISOString(),
    };
  } catch (err) {
    return {
      success: false,
      message: `Redis ping failed: ${err.message}`,
      error: err.code,
      timestamp: new Date().toISOString(),
    };
  }
}

/**
 * Get full application health status including Redis
 * @returns {Object} Application health status
 */
function getApplicationHealth() {
  return {
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    environment: process.env.NODE_ENV || 'development',
    redis: getRedisHealth(),
    memory: {
      heapUsed: Math.round(process.memoryUsage().heapUsed / 1024 / 1024) + 'MB',
      heapTotal: Math.round(process.memoryUsage().heapTotal / 1024 / 1024) + 'MB',
      external: Math.round(process.memoryUsage().external / 1024 / 1024) + 'MB',
    },
  };
}

module.exports = {
  getRedisHealth,
  pingRedis,
  getApplicationHealth,
};
