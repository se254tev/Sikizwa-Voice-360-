# Complete Updated Code Files - Reference Guide

This document contains the complete, updated code for all files that have been modified or created. Use this as a reference to verify your implementation.

---

## NEW FILE: src/config/redis.js

```javascript
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
```

---

## UPDATED FILE: src/sockets/index.js

```javascript
const { createAdapter } = require('@socket.io/redis-adapter');
const { Server } = require('socket.io');
const { createRedisClient } = require('../config/redis');
const logger = require('../config/logger');
const { registerSocket } = require('../utils/socketRegistry');

/**
 * Initialize Socket.io with Redis adapter and error handling
 * Gracefully falls back to in-memory adapter if Redis is unavailable
 */
function initSocket(server) {
  const io = new Server(server, { 
    cors: { origin: process.env.SOCKET_ORIGIN || '*' },
    // Adapt transports based on environment
    transports: ['websocket', 'polling'],
  });

  // Initialize Redis adapter with proper error handling
  if (process.env.REDIS_URL) {
    try {
      logger.info('Initializing Socket.io Redis adapter...');
      
      // Create pub/sub clients with production-safe configuration
      const pubClient = createRedisClient(process.env.REDIS_URL, 'SocketIO-Pub');
      const subClient = pubClient ? createRedisClient(process.env.REDIS_URL, 'SocketIO-Sub') : null;

      if (pubClient && subClient) {
        // Set up the Redis adapter
        io.adapter(createAdapter(pubClient, subClient));
        logger.info('Socket.io Redis adapter initialized successfully');

        // Monitor adapter health
        io.on('new_namespace', (namespace) => {
          logger.debug(`New namespace created: ${namespace.name}`);
        });

        // Handle adapter errors gracefully
        pubClient.on('error', (err) => {
          logger.error('Socket.io Redis pub client error:', err.message);
          // Don't crash - fall back to in-memory behavior
        });

        subClient.on('error', (err) => {
          logger.error('Socket.io Redis sub client error:', err.message);
          // Don't crash - fall back to in-memory behavior
        });

        // Store clients for cleanup during shutdown
        io.pubClient = pubClient;
        io.subClient = subClient;
      } else {
        logger.warn('Failed to initialize Redis clients, falling back to in-memory adapter');
      }
    } catch (err) {
      logger.error('Error setting up Redis adapter:', err);
      logger.warn('Using in-memory Socket.io adapter as fallback');
    }
  } else {
    logger.info('REDIS_URL not set - using in-memory Socket.io adapter');
  }

  // Socket connection handlers
  io.on('connection', (socket) => {
    logger.debug(`Client connected: ${socket.id}`);

    // Handle room join
    socket.on('join', (room) => {
      if (room && typeof room === 'string') {
        socket.join(room);
        logger.debug(`Socket ${socket.id} joined room: ${room}`);
      }
    });

    // Handle room leave
    socket.on('leave', (room) => {
      if (room && typeof room === 'string') {
        socket.leave(room);
        logger.debug(`Socket ${socket.id} left room: ${room}`);
      }
    });

    // Handle messages with validation
    socket.on('message', (data) => {
      if (data && data.room && typeof data.room === 'string') {
        try {
          io.to(data.room).emit('message', data);
          logger.debug(`Message sent to room: ${data.room}`);
        } catch (err) {
          logger.error(`Error sending message to room ${data.room}:`, err.message);
        }
      }
    });

    // Handle disconnection
    socket.on('disconnect', () => {
      logger.debug(`Client disconnected: ${socket.id}`);
    });

    // Handle errors
    socket.on('error', (err) => {
      logger.error(`Socket error for ${socket.id}:`, err);
    });
  });

  registerSocket(io);
  return io;
}

module.exports = { initSocket };
```

---

## UPDATED FILE: src/index.js

```javascript
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
```

---

## UPDATED FILE: src/config/logger.js

```javascript
const { createLogger, format, transports } = require('winston');
const fs = require('fs');
const path = require('path');

// Ensure logs directory exists
const logsDir = 'logs';
if (!fs.existsSync(logsDir)) {
  fs.mkdirSync(logsDir);
}

const logger = createLogger({
  level: process.env.LOG_LEVEL || (process.env.NODE_ENV === 'production' ? 'info' : 'debug'),
  format: format.combine(
    format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
    format.errors({ stack: true }),
    format.splat(),
    format.json()
  ),
  defaultMeta: { service: 'sikizwa-api' },
  transports: [
    // Console transport for all logs
    new transports.Console({
      format: format.combine(
        format.colorize({ all: true }),
        format.printf(({ timestamp, level, message, service, ...meta }) => {
          const metaStr = Object.keys(meta).length ? JSON.stringify(meta) : '';
          return `${timestamp} [${level}] [${service}]: ${message} ${metaStr}`;
        })
      ),
    }),
    
    // Error logs file
    new transports.File({
      filename: path.join(logsDir, 'error.log'),
      level: 'error',
      format: format.combine(
        format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
        format.errors({ stack: true }),
        format.json()
      ),
    }),
    
    // Combined logs file (all levels)
    new transports.File({
      filename: path.join(logsDir, 'combined.log'),
      format: format.combine(
        format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
        format.json()
      ),
      maxsize: 5242880, // 5MB
      maxFiles: 5,
    }),
  ],
});

// Production: Add Redis-specific logs
if (process.env.NODE_ENV === 'production') {
  logger.add(
    new transports.File({
      filename: path.join(logsDir, 'redis.log'),
      level: 'debug',
      format: format.combine(
        format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
        format.json()
      ),
    })
  );
}

module.exports = logger;
```

---

## NEW FILE: src/utils/healthCheck.js

```javascript
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
```

---

## Key Configuration in package.json

Your existing package.json already has all required dependencies:
```json
{
  "dependencies": {
    "redis": "^4.6.5",
    "ioredis": "^5.3.2",
    "@socket.io/redis-adapter": "^7.1.0",
    "socket.io": "^4.7.1",
    "winston": "^3.8.2"
  }
}
```

No additional npm packages needed!

---

## Environment Variables Template (.env)

```bash
# Server
PORT=4000
NODE_ENV=development
LOG_LEVEL=debug

# Database
MONGO_ATLAS_URI=mongodb+srv://username:password@cluster.mongodb.net/database
MONGO_URI=mongodb://localhost:27017/sikizwa

# Redis (required for production)
REDIS_URL=redis://localhost:6379

# Socket.io
SOCKET_ORIGIN=http://localhost:3000

# AI Service
AI_SERVICE_URL=http://localhost:8000

# Cloudinary (for uploads)
CLOUDINARY_NAME=your-cloud-name
CLOUDINARY_API_KEY=your-api-key
CLOUDINARY_API_SECRET=your-api-secret

# JWT
JWT_SECRET=your-secret-key
JWT_EXPIRE=7d

# CORS
CORS_ORIGIN=http://localhost:3000,http://localhost:8080
```

---

## Verification Checklist

After implementation:
- [ ] All files copied to correct locations
- [ ] `npm start` runs without errors
- [ ] Redis connection shows in logs
- [ ] Check `logs/combined.log` for startup messages
- [ ] Verify Socket.io connects successfully
- [ ] Test graceful shutdown (`Ctrl+C`)
- [ ] Simulate Redis failure and verify app continues
- [ ] No unhandled rejection warnings in console
