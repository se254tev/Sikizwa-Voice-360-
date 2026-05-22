require('dotenv').config();
const http = require('http');
const app = require('./app');
const { connectDB } = require('./config/db');
const { initSocket } = require('./sockets');
const { initializeRedis, closeRedis, isRedisReady } = require('./config/redis');
const logger = require('./config/logger');

const PORT = process.env.PORT || 4000;

let server;

/**
 * Graceful shutdown handler
 */
async function gracefulShutdown(signal) {
  logger.info(`Received signal: ${signal}, starting graceful shutdown...`);

  // Stop accepting new requests
  if (server) {
    server.close(async () => {
      logger.info('Server closed, cleaning up connections...');

      try {
        // Close Redis connection
        await closeRedis();
        logger.info('Redis connection closed');
      } catch (err) {
        logger.error('Error closing Redis:', err);
      }

      logger.info('Graceful shutdown completed');
      process.exit(0);
    });

    // Force shutdown after 30 seconds
    setTimeout(() => {
      logger.error('Graceful shutdown timeout, forcing exit');
      process.exit(1);
    }, 30000);
  } else {
    process.exit(0);
  }
}

/**
 * Initialize and start the application
 */
async function start() {
  try {
    // Connect to MongoDB
    await connectDB(process.env.MONGO_ATLAS_URI || process.env.MONGO_URI);
    logger.info('Connected to MongoDB');

    // Initialize Redis
    initializeRedis();
    if (isRedisReady()) {
      logger.info('Redis initialized');
    } else {
      logger.warn(
        'Redis not immediately available, continuing anyway. ' +
        'Redis connection will be established asynchronously.'
      );
    }

    // Create HTTP server and initialize Socket.io
    server = http.createServer(app);
    initSocket(server);

    // Start listening
    server.listen(PORT, () => {
      logger.info(`Sikizwa backend listening on port ${PORT}`);
      logger.info(`Environment: ${process.env.NODE_ENV || 'development'}`);
      logger.info(`Redis URL: ${process.env.REDIS_URL ? '***configured***' : 'not configured'}`);
    });

    // Register graceful shutdown handlers
    process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
    process.on('SIGINT', () => gracefulShutdown('SIGINT'));

    // Handle uncaught exceptions
    process.on('uncaughtException', (err) => {
      logger.error('Uncaught Exception:', err);
      gracefulShutdown('uncaughtException');
    });

    // Handle unhandled promise rejections
    process.on('unhandledRejection', (reason, promise) => {
      logger.error('Unhandled Rejection at:', promise, 'reason:', reason);
      // Don't exit on unhandled rejection, just log it
      // unless it's critical
    });

  } catch (err) {
    logger.error('Failed to start server:', err);
    process.exit(1);
  }
}

// Start the application
start();
