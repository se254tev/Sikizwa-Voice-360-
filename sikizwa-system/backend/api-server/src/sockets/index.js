const { createAdapter } = require('@socket.io/redis-adapter');
const { Server } = require('socket.io');
const Redis = require('ioredis');
const { registerSocket } = require('../utils/socketRegistry');

function initSocket(server){
  const io = new Server(server, { cors: { origin: process.env.SOCKET_ORIGIN || '*' } });
  if(process.env.REDIS_URL){
    const pubClient = new Redis(process.env.REDIS_URL);
    const subClient = pubClient.duplicate();
    io.adapter(createAdapter(pubClient, subClient));
  }

  io.on('connection', socket => {
    socket.on('join', (room) => {
      socket.join(room);
    });
    socket.on('leave', (room) => {
      socket.leave(room);
    });
    socket.on('message', (data) => {
      if(data && data.room) io.to(data.room).emit('message', data);
    });
  });

  registerSocket(io);
  return io;
}

module.exports = { initSocket };
