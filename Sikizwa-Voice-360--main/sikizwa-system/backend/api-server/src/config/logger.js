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
