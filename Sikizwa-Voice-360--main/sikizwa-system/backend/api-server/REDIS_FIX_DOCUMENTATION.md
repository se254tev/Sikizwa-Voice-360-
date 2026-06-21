# Redis Connection Fix Documentation

## Overview

This document describes the comprehensive fixes applied to resolve Redis connection issues in the Sikizwa Node.js backend, including proper error handling, retry strategies, and graceful degradation.

## Issues Fixed

### 1. **Missing Error Handlers** ❌ → ✅
- **Problem**: Redis clients in `src/sockets/index.js` had no `error` event handlers, causing unhandled errors to crash the application.
- **Solution**: Added comprehensive event listeners for all connection lifecycle events:
  - `connect` - Connection established
  - `ready` - Client fully operational
  - `error` - Handle errors without crashing
  - `close` - Connection closed
  - `reconnecting` - Retry in progress
  - `end` - Final disconnection

### 2. **MaxRetriesPerRequestError** ❌ → ✅
- **Problem**: Redis clients had default retry configuration that exhausted retries (limit: 20).
- **Solution**: Configure retry strategy with:
  - `maxRetriesPerRequest: null` - Allow unlimited retries for individual commands
  - `retryStrategy()` - Exponential backoff (50ms to 2000ms)
  - `commandTimeout: 5000` - 5-second timeout per command

### 3. **Application Crashes on Redis Unavailability** ❌ → ✅
- **Problem**: Application crashed when Redis connection failed.
- **Solution**: 
  - All Redis operations are wrapped with error handling
  - Socket.io gracefully falls back to in-memory adapter if Redis unavailable
  - Background jobs continue to function without Redis

### 4. **Lack of Connection Monitoring** ❌ → ✅
- **Problem**: No visibility into Redis connection status.
- **Solution**: 
  - Enhanced Winston logger with Redis-specific logging
  - Added health check utilities in `src/utils/healthCheck.js`
  - Graceful logging for all connection state changes

### 5. **No Graceful Shutdown** ❌ → ✅
- **Problem**: Application didn't cleanly close Redis connections on shutdown.
- **Solution**: Implemented graceful shutdown handlers:
  - `SIGTERM` and `SIGINT` signal handlers
  - Proper cleanup of Redis connections
  - 30-second timeout for graceful shutdown

---

## Files Created/Modified

### 1. **NEW: `src/config/redis.js`** - Centralized Redis Configuration
```javascript
// Exports:
- createRedisClient(url, name) - Create a configured Redis client
- initializeRedis() - Initialize main Redis client
- getRedisClient() - Get the main Redis client
- isRedisReady() - Check if Redis is ready
- closeRedis() - Gracefully close connections
```

**Key Features:**
- Production-safe configuration with retry strategies
- All required event handlers for connection lifecycle
- Exponential backoff retry strategy
- Connection timeout and command timeout settings
- Automatic reconnection on specific errors
- Graceful error logging without crashes

### 2. **UPDATED: `src/sockets/index.js`** - Socket.io with Redis Adapter
**Changes:**
- Uses centralized `createRedisClient()` instead of direct `new Redis()`
- Proper error handling for both pub and sub clients
- Graceful fallback to in-memory adapter if Redis fails
- Enhanced socket event handlers with logging
- Input validation for socket messages
- Connection and disconnection lifecycle logging

### 3. **UPDATED: `src/index.js`** - Main Entry Point
**Changes:**
- Initializes Redis before starting server
- Adds graceful shutdown handlers (`SIGTERM`, `SIGINT`)
- Handles uncaught exceptions and unhandled promise rejections
- Proper cleanup of connections during shutdown
- Enhanced startup logging with Redis status
- 30-second timeout for graceful shutdown

### 4. **UPDATED: `src/config/logger.js`** - Enhanced Logging
**Changes:**
- Added file transports for persistent logging:
  - `logs/error.log` - Error level logs
  - `logs/combined.log` - All log levels (with rotation)
  - `logs/redis.log` - Redis-specific logs (production only)
- Improved console output formatting
- Better timestamp and metadata tracking
- Log rotation (5MB max file size, 5 files retained)

### 5. **NEW: `src/utils/healthCheck.js`** - Redis Health Monitoring
```javascript
// Exports:
- getRedisHealth() - Get Redis connection status
- pingRedis() - Ping Redis to verify connectivity
- getApplicationHealth() - Full application health status
```

---

## Configuration

### Environment Variables

Create or update `.env` file with:

```bash
# Required
REDIS_URL=redis://localhost:6379

# Optional
LOG_LEVEL=debug               # debug, info, warn, error
NODE_ENV=development          # development, production
SOCKET_ORIGIN=*               # WebSocket CORS origin

# MongoDB
MONGO_ATLAS_URI=mongodb+srv://...
MONGO_URI=mongodb://localhost:27017/sikizwa

# Port
PORT=4000
```

### Docker Environment

For Docker deployments, ensure Redis is accessible:

```dockerfile
# In your Dockerfile or docker-compose.yml
REDIS_URL=redis://redis-service:6379

# Or if using Redis with authentication:
REDIS_URL=redis://:password@redis-service:6379/0
```

---

## Connection Lifecycle

### Successful Connection
```
1. Redis client created with configuration
2. connect event → logging connection established
3. ready event → Redis client fully operational
4. Application continues normally
```

### Connection Failure with Retry
```
1. Connection attempt fails
2. error event → log error, set isRedisAvailable=false
3. reconnecting event → attempt reconnection with exponential backoff
4. On successful reconnection → ready event
5. Application continues without interruption
```

### Application Graceful Shutdown
```
1. SIGTERM/SIGINT received
2. Stop accepting new requests
3. closeRedis() called → gracefully disconnect Redis
4. Server closed → process exit
```

---

## Production Recommendations

### 1. **Docker Compose Setup**
```yaml
version: '3.8'
services:
  api:
    build: .
    ports:
      - "4000:4000"
    environment:
      REDIS_URL: redis://redis:6379
      NODE_ENV: production
    depends_on:
      - redis
    restart: unless-stopped

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    volumes:
      - redis-data:/data
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 5s
      timeout: 3s
      retries: 5

volumes:
  redis-data:
```

### 2. **Health Check Endpoint**
Add to your Express routes to monitor Redis:

```javascript
const { getApplicationHealth, pingRedis } = require('../utils/healthCheck');

app.get('/health', (req, res) => {
  res.json(getApplicationHealth());
});

app.get('/health/redis', async (req, res) => {
  const result = await pingRedis();
  res.status(result.success ? 200 : 503).json(result);
});
```

### 3. **Monitoring & Logging**
- Check logs in `logs/` directory:
  - `error.log` - Issues to investigate
  - `redis.log` - Redis-specific events (production)
  - `combined.log` - Full application logs

### 4. **Graceful Shutdown in Production**
The application now properly handles:
- `docker stop` (sends SIGTERM) → graceful shutdown
- `kill -SIGTERM <pid>` → graceful shutdown
- Unhandled exceptions → logged with stack trace

---

## Troubleshooting

### Issue: "Redis error - connect ECONNREFUSED"
**Solution**: Ensure Redis is running and `REDIS_URL` is correct
```bash
# Test Redis connection
redis-cli -u redis://localhost:6379 ping
# Should return: PONG
```

### Issue: "Reached the max retries per request limit"
**Fixed** ✅ - Now uses `maxRetriesPerRequest: null` with exponential backoff

### Issue: "missing 'error' handler"
**Fixed** ✅ - All Redis clients now have proper error handlers

### Issue: Application still crashes
Check logs:
```bash
tail -f logs/error.log
tail -f logs/redis.log     # production only
```

---

## Testing

### Unit Test Template
```javascript
const { getRedisClient, isRedisReady } = require('../config/redis');

describe('Redis Configuration', () => {
  it('should initialize Redis client', () => {
    const client = getRedisClient();
    expect(client).toBeDefined();
  });

  it('should report Redis ready status', (done) => {
    // Test implementation
    done();
  });
});
```

### Manual Testing
```bash
# Start server
npm start

# In another terminal, check health
curl http://localhost:4000/health
curl http://localhost:4000/health/redis

# Stop and restart Redis to test recovery
# Server should continue functioning
```

---

## Backward Compatibility

✅ **All existing functionality preserved**
- Socket.io messaging works the same
- No breaking changes to routes or controllers
- Gradual fallback if Redis unavailable
- Existing error handlers still work

---

## Performance Impact

- **Minimal overhead**: Connection pooling already built into ioredis
- **Memory**: Slightly increased logging, mitigated by log rotation
- **CPU**: Negligible impact from event handlers
- **Network**: Improved with better retry strategy

---

## Migration Checklist

- [ ] Review `.env` file, ensure `REDIS_URL` is set correctly
- [ ] Restart application: `npm start`
- [ ] Check logs: `tail -f logs/combined.log`
- [ ] Test health endpoint: `curl http://localhost:4000/health`
- [ ] Test Redis connection: `curl http://localhost:4000/health/redis`
- [ ] Verify Socket.io functionality works
- [ ] Test graceful shutdown: `docker stop <container>` or `Ctrl+C`
- [ ] Monitor Redis logs during production deployment

---

## Support

For issues or questions:
1. Check `logs/error.log` for detailed error information
2. Verify `REDIS_URL` configuration
3. Ensure Redis service is running and accessible
4. Check network connectivity from application to Redis server

---

## Changelog

### v1.0.0 (Current)
- ✅ Added centralized Redis configuration module
- ✅ Implemented all required event handlers
- ✅ Added exponential backoff retry strategy
- ✅ Implemented graceful shutdown
- ✅ Enhanced logging with file transports
- ✅ Added health check utilities
- ✅ Updated Socket.io with error handling
- ✅ Maintained backward compatibility
