const Redis = require('ioredis');
const logger = require('./logger');

/**
 * Centralized Redis client configuration with proper error handling
 * and retry strategies to prevent connection failures
 */

let redisClient = null;
let isRedisAvailable = false;

/**
 * Create a Redis client with production-safe configuration
 * @param {string} url - Redis connection URL
 * @param {string} name - Client name for logging
 * @returns {Redis} Configured Redis client
 */
function createRedisClient(url, name = 'Redis') {
  if (!url) {
    logger.warn(`${name} URL not provided, Redis will be disabled`);
    return null;
  }

  const client = new Redis(url, {
    // Retry strategy with exponential backoff
    retryStrategy: (times) => {
      const delay = Math.min(times * 50, 2000);
      logger.debug(`${name}: Retrying connection (attempt ${times})...`);
      return delay;
    },
    
    // Maximum 20 retries before giving up (default behavior, but explicit)
    maxRetriesPerRequest: null, // Allows unlimited retries for commands
    
    // Disable ready check to speed up connections in some scenarios
    enableReadyCheck: false,
    
    // Connection timeout
    connectTimeout: 10000,
    
    // Command timeout
    commandTimeout: 5000,
    
    // Reconnect on error
    reconnectOnError: (err) => {
      const targetError = 'READONLY';
      if (err.message.includes(targetError)) {
        logger.warn(`${name}: READONLY error detected, attempting reconnection`);
        return true; // Reconnect
      }
      return false;
    },
    
    // Disable offline queue to prevent memory buildup
    enableOfflineQueue: true,
    
    // Lazy connect to avoid immediate connection attempts
    lazyConnect: false,
    
    // Enable auto resend of unfulfilled commands
    autoResendUnfulfilledCommands: true,
    
    // Max reconnect timeout
    maxRetriesPerRequest: null,
  });

  // ===== CONNECTION LIFECYCLE HANDLERS =====

  /**
   * Handle successful connection
   */
  client.on('connect', () => {
    isRedisAvailable = true;
    logger.info(`${name}: Connected to Redis`);
  });

  /**
   * Handle ready state (fully operational)
   */
  client.on('ready', () => {
    isRedisAvailable = true;
    logger.info(`${name}: Redis client is ready`);
  });

  /**
   * Handle errors to prevent unhandled rejections
   */
  client.on('error', (err) => {
    isRedisAvailable = false;
    logger.error(`${name}: Redis error - ${err.message}`, {
      error: err.message,
      code: err.code,
      stack: err.stack,
    });
    
    // Don't crash the application on Redis errors
    // The application will continue to function without Redis
  });

  /**
   * Handle reconnection attempts
   */
  client.on('reconnecting', (info) => {
    logger.warn(`${name}: Attempting to reconnect to Redis (attempt ${info.attempt})`);
  });

  /**
   * Handle disconnection/close
   */
  client.on('close', () => {
    isRedisAvailable = false;
    logger.warn(`${name}: Redis connection closed`);
  });

  /**
   * Handle end of connection (final close, no reconnect)
   */
  client.on('end', () => {
    isRedisAvailable = false;
    logger.info(`${name}: Redis connection ended`);
  });

  /**
   * Handle subscription/psubscription messages
   */
  client.on('message', (channel, message) => {
    logger.debug(`${name}: Received message on channel ${channel}`);
  });

  /**
   * Handle pattern-based subscriptions
   */
  client.on('pmessage', (pattern, channel, message) => {
    logger.debug(`${name}: Received message on pattern ${pattern} from channel ${channel}`);
  });

  return client;
}

/**
 * Initialize main Redis client for general use
 * @returns {Redis|null} Redis client or null if not configured
 */
function initializeRedis() {
  redisClient = createRedisClient(process.env.REDIS_URL, 'RedisClient');
  return redisClient;
}

/**
 * Get the main Redis client
 * @returns {Redis|null} Redis client
 */
function getRedisClient() {
  return redisClient;
}

/**
 * Check if Redis is currently available
 * @returns {boolean} true if Redis is connected and ready
 */
function isRedisReady() {
  return isRedisAvailable && redisClient && redisClient.status === 'ready';
}

/**
 * Gracefully close Redis connection
 * @returns {Promise<void>}
 */
async function closeRedis() {
  if (redisClient) {
    try {
      await redisClient.quit();
      logger.info('Redis connection closed gracefully');
    } catch (err) {
      logger.error('Error closing Redis connection', err);
      // Force disconnect if graceful close fails
      redisClient.disconnect();
    }
  }
}

module.exports = {
  createRedisClient,
  initializeRedis,
  getRedisClient,
  isRedisReady,
  closeRedis,
};
