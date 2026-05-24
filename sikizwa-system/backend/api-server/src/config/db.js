const mongoose = require('mongoose');
const User = require('../models/User');
const logger = require('./logger');

function isIgnorableIndexError(err) {
  if (!err) {
    return false;
  }

  const message = String(err.message || '');
  const codeName = err.codeName || err.name || '';

  return (
    codeName === 'IndexKeySpecsConflict' ||
    codeName === 'IndexOptionsConflict' ||
    message.includes('IndexKeySpecsConflict') ||
    message.includes('IndexOptionsConflict')
  );
}

async function synchronizeIndexes() {
  try {
    await User.syncIndexes();
    logger.info('Indexes synchronized successfully');
    return true;
  } catch (err) {
    if (isIgnorableIndexError(err)) {
      logger.warn('Index conflict detected, skipping safe initialization');
      logger.warn(`MongoDB index conflict detected while synchronizing indexes: ${err.message}`);
      return false;
    }

    logger.error('MongoDB index synchronization failed:', err);
    return false;
  }
}

async function connectDB(uri) {
  if (!uri) {
    logger.error('MongoDB connection skipped: MONGO_URI not set');
    return false;
  }

  try {
    await mongoose.connect(uri, {
      connectTimeoutMS: 10000,
      serverSelectionTimeoutMS: 10000,
    });

    logger.info('MongoDB connected');
    await synchronizeIndexes();
    return true;
  } catch (err) {
    logger.error('MongoDB connection failed:', err);
    return false;
  }
}

module.exports = { connectDB };
