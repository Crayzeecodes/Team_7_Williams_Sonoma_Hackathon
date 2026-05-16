const jwt = require("jsonwebtoken");
const User = require("../models/User");

async function auth(req, res, next) {
  const authHeader = req.headers.authorization || "";
  const token = authHeader.startsWith("Bearer ") ? authHeader.slice(7) : null;

  if (token) {
    try {
      const payload = jwt.verify(token, process.env.JWT_SECRET || "hackathon-secret");
      const user = await User.findById(payload.userId);
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

  let user = await User.findOne({ email: headerEmail });
  if (!user) {
    user = await User.create({
      email: headerEmail,
      password: "ios-demo-user",
      name: headerName || "Williams Sonoma Guest",
      addresses: [],
      createdAt: new Date(),
    });
  } else if (headerName && user.name !== headerName) {
    user.name = headerName;
    await user.save();
  }

  req.user = user;
  return next();
}

module.exports = auth;
