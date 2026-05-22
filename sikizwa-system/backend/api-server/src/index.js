require('dotenv').config();
const http = require('http');
const app = require('./app');
const { connectDB } = require('./config/db');
const { initSocket } = require('./sockets');
const logger = require('./config/logger');

const PORT = process.env.PORT || 4000;

async function start() {
  await connectDB(process.env.MONGO_ATLAS_URI || process.env.MONGO_URI);
  const server = http.createServer(app);
  initSocket(server);
  server.listen(PORT, () => {
    logger.info('Sikizwa backend listening on port %d', PORT);
  });
}

start().catch(err => {
  console.error('Failed to start server', err);
  process.exit(1);
});
