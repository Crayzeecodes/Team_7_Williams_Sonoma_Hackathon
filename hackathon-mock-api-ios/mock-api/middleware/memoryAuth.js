const jwt = require("jsonwebtoken");
const memoryStore = require("../services/memoryStore");

function memoryAuth(req, res, next) {
  const authHeader = req.headers.authorization || "";
  const token = authHeader.startsWith("Bearer ") ? authHeader.slice(7) : null;

  if (token) {
    try {
      const payload = jwt.verify(token, process.env.JWT_SECRET || "hackathon-secret");
      const user = memoryStore.findUserById(payload.userId);
      if (!user) {
        return res.status(401).json({ message: "Authenticated user not found" });
      }
      req.user = user;
      return next();
    } catch (error) {
      return res.status(401).json({ message: "Invalid token" });
    }
  }

  const headerEmail = String(req.headers["x-user-email"] || "").trim().toLowerCase();
  const headerName = String(req.headers["x-user-name"] || "").trim();
  if (!headerEmail) {
    return res.status(401).json({ message: "Authorization required" });
  }

  req.user = memoryStore.ensureUser({
    email: headerEmail,
    password: "ios-demo-user",
    name: headerName || "Williams Sonoma Guest",
  });

  return next();
}

module.exports = memoryAuth;
