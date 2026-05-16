const jwt = require("jsonwebtoken");

const JWT_SECRET = process.env.JWT_SECRET || "hackathon-secret-key";

// Demo user used when no token is provided (hackathon convenience)
const DEMO_USER = {
  id: "demo-user-001",
  email: "demo@hackathon.com",
  name: "Demo User",
};

/**
 * JWT auth middleware.
 * Attaches req.user from the JWT payload.
 * Falls back to DEMO_USER if no token is present (hackathon mode).
 */
const auth = (req, res, next) => {
  const authHeader = req.headers["authorization"];

  if (!authHeader) {
    // Hackathon fallback: allow unauthenticated requests as demo user
    req.user = DEMO_USER;
    return next();
  }

  const token = authHeader.startsWith("Bearer ")
    ? authHeader.slice(7)
    : authHeader;

  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    req.user = {
      id: decoded.id || decoded.sub || decoded.userId || DEMO_USER.id,
      email: decoded.email || DEMO_USER.email,
      name: decoded.name || DEMO_USER.name,
    };
    next();
  } catch (err) {
    // Invalid token → also fall back to demo user for hackathon ease
    req.user = DEMO_USER;
    next();
  }
};

module.exports = auth;
