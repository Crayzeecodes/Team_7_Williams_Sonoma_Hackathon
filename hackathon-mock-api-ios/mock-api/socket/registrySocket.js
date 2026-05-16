/**
 * Socket.IO Registry Room Management
 * -----------------------------------
 * Call initRegistrySocket(io) once after creating the HTTP server.
 * Clients emit "joinRoom" with a registryId to subscribe to real-time updates.
 */

let _io = null;

function initRegistrySocket(io) {
  _io = io;

  io.on("connection", (socket) => {
    console.log(`🔌 Socket connected: ${socket.id}`);

    // Client joins a registry room
    socket.on("joinRoom", (registryId) => {
      if (!registryId) return;
      socket.join(registryId);
      console.log(`📦 Socket ${socket.id} joined room: ${registryId}`);
    });

    // Client leaves a registry room
    socket.on("leaveRoom", (registryId) => {
      if (!registryId) return;
      socket.leave(registryId);
      console.log(`📤 Socket ${socket.id} left room: ${registryId}`);
    });

    socket.on("disconnect", () => {
      console.log(`🔌 Socket disconnected: ${socket.id}`);
    });
  });
}

// ─── Emit helpers called from routes ───────────────────────────────────────────

function emitCartUpdated(registryId, cartItems, budgetSnapshot) {
  if (!_io) return;
  _io.to(registryId).emit("registry:cartUpdated", {
    registryId,
    cartItems,
    budgetSnapshot,
  });
}

function emitMemberJoined(registryId, member) {
  if (!_io) return;
  _io.to(registryId).emit("registry:memberJoined", {
    registryId,
    member,
  });
}

function emitMemberLeft(registryId, userId) {
  if (!_io) return;
  _io.to(registryId).emit("registry:memberLeft", {
    registryId,
    userId,
  });
}

function emitBudgetUpdated(registryId, budgetSnapshot) {
  if (!_io) return;
  _io.to(registryId).emit("registry:budgetUpdated", {
    registryId,
    budgetSnapshot,
  });
}

function emitRegistryCreated(registry) {
  if (!_io) return;
  _io.emit("registry:created", { registry });
}

module.exports = {
  initRegistrySocket,
  emitCartUpdated,
  emitMemberJoined,
  emitMemberLeft,
  emitBudgetUpdated,
  emitRegistryCreated,
};
