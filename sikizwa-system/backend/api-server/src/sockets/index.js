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
