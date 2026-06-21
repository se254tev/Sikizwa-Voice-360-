let io = null;

function registerSocket(serverIo) {
  io = serverIo;
}

function getSocket() {
  return io;
}

module.exports = { registerSocket, getSocket };
