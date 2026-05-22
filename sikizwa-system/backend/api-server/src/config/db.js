const mongoose = require('mongoose');

async function connectDB(uri){
  if(!uri) throw new Error('MONGO_URI not set');
  await mongoose.connect(uri, {
    connectTimeoutMS: 10000
  });
  console.log('Connected to MongoDB');
}

module.exports = { connectDB };
