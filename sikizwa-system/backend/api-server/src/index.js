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

  if (server) {
    server.close(async () => {
      logger.info('Server closed, cleaning up connections...');

      try {
        await closeRedis();
        logger.info('Redis connection closed');
      } catch (err) {
        logger.error('Error closing Redis:', err);
      }

      logger.info('Graceful shutdown completed');
      process.exit(0);
    });

    setTimeout(() => {
      logger.error('Graceful shutdown timeout, forcing exit');
      process.exit(1);
    }, 30000);
  } else {
    process.exit(0);
  }
}

function registerShutdownHandlers() {
  process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
  process.on('SIGINT', () => gracefulShutdown('SIGINT'));

  process.on('uncaughtException', (err) => {
    logger.error('Uncaught Exception:', err);
    gracefulShutdown('uncaughtException');
  });

  process.on('unhandledRejection', (reason, promise) => {
    logger.error('Unhandled Rejection at:', promise, 'reason:', reason);
  });
}

async function start() {
  try {
    server = http.createServer(app);
    initSocket(server);

    server.listen(PORT, () => {
      logger.info(`Server running on port ${PORT}`);
      logger.info(`Environment: ${process.env.NODE_ENV || 'development'}`);
      logger.info(`Redis URL: ${process.env.REDIS_URL ? '***configured***' : 'not configured'}`);
    });

    registerShutdownHandlers();

    initializeRedis();
    if (isRedisReady()) {
      logger.info('Redis initialized');
    } else {
      logger.warn(
        'Redis not immediately available, continuing anyway. ' +
        'Redis connection will be established asynchronously.'
      );
    }

    await connectDB(process.env.MONGO_ATLAS_URI || process.env.MONGO_URI);
  } catch (err) {
    logger.error('Failed to start server:', err);
  }
}

start();
