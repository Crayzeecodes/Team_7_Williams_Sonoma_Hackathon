let ioInstance = null;

function initializeRegistrySocket(io) {
  ioInstance = io;

  io.on("connection", (socket) => {
    socket.on("joinRoom", async (registryId) => {
      if (registryId) {
        await socket.join(String(registryId));
      }
    });

    socket.on("leaveRoom", async (registryId) => {
      if (registryId) {
        await socket.leave(String(registryId));
      }
    });
  });
}

function emitToRegistry(registryId, event, payload) {
  if (!ioInstance || !registryId) {
    return;
  }
  ioInstance.to(String(registryId)).emit(event, payload);
}

function emitRegistryCreated(registry) {
  if (!ioInstance) {
    return;
  }
  ioInstance.emit("registry:created", registry);
}

module.exports = {
  initializeRegistrySocket,
  emitToRegistry,
  emitRegistryCreated,
};
