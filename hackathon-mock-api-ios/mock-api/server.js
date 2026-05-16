const express = require("express");
const http = require("http");
const { Server } = require("socket.io");
const fs = require("fs");
const path = require("path");
const mongoose = require("mongoose");
const cors = require("cors");
require("dotenv").config();

const app = express();
const server = http.createServer(app);

// ─── Socket.IO ─────────────────────────────────────────────────────────────────
const io = new Server(server, {
  cors: { origin: "*", methods: ["GET", "POST"] },
});
const { initRegistrySocket } = require("./socket/registrySocket");
initRegistrySocket(io);

const PORT = process.env.PORT || 3001;

// ─── Middleware ────────────────────────────────────────────────────────────────
app.use(cors());
app.use(express.json());

// ─── MongoDB ───────────────────────────────────────────────────────────────────
if (process.env.MONGO_URI) {
  console.log("⏳ Connecting to MongoDB Atlas...");
  mongoose
    .connect(process.env.MONGO_URI, {
      serverSelectionTimeoutMS: 5000, // Timeout after 5 seconds instead of default 30s
    })
    .then(() => console.log("✅ Connected to MongoDB Atlas"))
    .catch((err) => {
      console.error("❌ MongoDB Connection Error:", err.message);
      console.warn("⚠️  Falling back to buffering (operations will wait for connection)");
    });
} else {
  console.warn("⚠️  MONGO_URI not set in .env — registry routes will fail");
}

// ─── Static Images ─────────────────────────────────────────────────────────────
app.use("/images", express.static(path.join(__dirname, "images")));

// ─── JSON file helpers (existing mock routes) ──────────────────────────────────
function readJson(fileName) {
  const filePath = path.join(__dirname, "responses", fileName);
  return JSON.parse(fs.readFileSync(filePath, "utf8"));
}

function delayedJson(res, fileName, status = 200, delay = 500) {
  setTimeout(() => {
    res.status(status).json(readJson(fileName));
  }, delay);
}

// ─── Existing Mock Routes ──────────────────────────────────────────────────────
app.get("/health", (req, res) => {
  res.json({ status: "ok" });
});

app.post("/login", (req, res) => {
  const { email, password } = req.body || {};
  if (email === "demo@hackathon.com" && password === "123456") {
    return delayedJson(res, "login_success.json", 200, 400);
  }
  return delayedJson(res, "error_401.json", 401, 400);
});

app.get("/profile", (req, res) => {
  return delayedJson(res, "profile.json", 200, 600);
});

app.get("/feed", (req, res) => {
  return delayedJson(res, "feed.json", 200, 700);
});

app.get("/skus", (req, res) => {
  return delayedJson(res, "skus.json", 200, 700);
});

// ─── Registry API Routes ───────────────────────────────────────────────────────
const registryRouter = require("./routes/registry");
app.use("/api/registry", registryRouter);

// ─── Start Server ──────────────────────────────────────────────────────────────
server.listen(PORT, "0.0.0.0", () => {
  console.log(`🚀 Mock API running on http://0.0.0.0:${PORT}`);
  console.log(`🔌 Socket.IO ready`);
});