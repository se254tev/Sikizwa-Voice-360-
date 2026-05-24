const mongoose = require('mongoose');
const User = require('../models/User');

async function connectDB(uri){
  if(!uri) throw new Error('MONGO_URI not set');
  await mongoose.connect(uri, {
    connectTimeoutMS: 10000
  });
  await User.syncIndexes();
  console.log('Connected to MongoDB');
}

module.exports = { connectDB };
