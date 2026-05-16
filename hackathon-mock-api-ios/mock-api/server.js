const express = require("express");
const fs = require("fs");
const path = require("path");
const mongoose = require("mongoose");
const cors = require("cors");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
require("dotenv").config();
const User = require("./models/User");
const Registry = require("./models/Registry");
const Product = require("./models/Product");

const app = express();
const PORT = process.env.PORT || 3001;

// Middleware
app.use(cors());
app.use(express.json());

// Connect to MongoDB
mongoose.connect(process.env.MONGO_URI)
.then(() => console.log('✅ Connected to MongoDB Atlas'))
.catch(err => console.error('❌ MongoDB Connection Error:', err));

// Serve image files from the local "images" directory
// Handles URLs like /images//img17m.jpg (double-slash from paths starting with "/")
app.use("/images", express.static(path.join(__dirname, "images")));

function readJson(fileName) {
  const filePath = path.join(__dirname, "responses", fileName);
  return JSON.parse(fs.readFileSync(filePath, "utf8"));
}

function delayedJson(res, fileName, status = 200, delay = 500) {
  setTimeout(() => {
    res.status(status).json(readJson(fileName));
  }, delay);
}

app.get("/health", (req, res) => {
  res.json({ status: "ok" });
});

// JWT Secret from env or fallback
const JWT_SECRET = process.env.JWT_SECRET || 'hackathon_super_secret_key';

// AUTHENTICATION ENDPOINTS
app.post("/auth/register", async (req, res) => {
  try {
    const { name, email, password } = req.body;
    
    // Check if user exists
    let user = await User.findOne({ email });
    if (user) {
      return res.status(400).json({ message: "User already exists" });
    }

    // Hash password
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    // Create user
    user = new User({
      name,
      email,
      password: hashedPassword
    });

    await user.save();

    // Create JWT
    const payload = { user: { id: user.id } };
    const token = jwt.sign(payload, JWT_SECRET, { expiresIn: '7d' });

    res.json({ token, user: { id: user.id, name: user.name, email: user.email } });
  } catch (err) {
    console.error(err.message);
    res.status(500).send("Server Error");
  }
});

app.post("/auth/login", async (req, res) => {
  try {
    const { email, password } = req.body;

    // Check if user exists
    let user = await User.findOne({ email });
    if (!user) {
      return res.status(400).json({ message: "Invalid Credentials" });
    }

    // Check password
    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.status(400).json({ message: "Invalid Credentials" });
    }

    // Create JWT
    const payload = { user: { id: user.id } };
    const token = jwt.sign(payload, JWT_SECRET, { expiresIn: '7d' });

    res.json({ token, user: { id: user.id, name: user.name, email: user.email } });
  } catch (err) {
    console.error(err.message);
    res.status(500).send("Server Error");
  }
});

// AUTH MIDDLEWARE
const auth = (req, res, next) => {
  // Get token from header
  const token = req.header("x-auth-token") || req.header("Authorization")?.replace("Bearer ", "");
  if (!token) {
    return res.status(401).json({ message: "No token, authorization denied" });
  }
  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    req.user = decoded.user;
    next();
  } catch (err) {
    res.status(401).json({ message: "Token is not valid" });
  }
};

// REGISTRY ENDPOINTS
app.post("/registries", auth, async (req, res) => {
  try {
    const {
      name,
      joinCode,
      registryType,
      creatorName,
      eventType,
      eventDate,
      eventDetails,
      giftingDetails,
      shippingAddress
    } = req.body;

    // Create the registry
    const registry = new Registry({
      adminId: req.user.id,
      name,
      joinCode,
      registryType,
      creatorName,
      eventType,
      eventDate,
      eventDetails,
      giftingDetails,
      shippingAddress,
      members: [{ userId: req.user.id, role: 'admin', contributedBudget: 0 }]
    });

    // Recalculate initial budget
    registry.recalculateBudget();

    await registry.save();
    res.status(201).json(registry);
  } catch (err) {
    console.error(err.message);
    res.status(500).json({ message: "Server Error", error: err.message });
  }
});

app.get("/registries", auth, async (req, res) => {
  try {
    // Get registries where user is a member
    const registries = await Registry.find({ "members.userId": req.user.id })
                                     .populate("adminId", "name email")
                                     .sort({ createdAt: -1 });
    res.json(registries);
  } catch (err) {
    console.error(err.message);
    res.status(500).send("Server Error");
  }
});

// LEGACY MOCK ENDPOINTS (Kept for compatibility)
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

app.get("/skus", async (req, res) => {
  try {
    const products = await Product.find({});
    
    // Map MongoDB products to the structure expected by the iOS app (ProductItemDTO)
    const dtos = products.map(p => ({
      id: p.skuId,
      name: p.name,
      shortName: p.name,
      primaryGroupId: p.skuId,
      price: {
        regularPrice: p.price,
        sellingPrice: p.price,
        retailPrice: p.price
      },
      properties: {
        name: p.name,
        shortName: p.name,
        productType: p.category
      },
      media: {
        images: (p.images || []).map(img => ({
          type: "prodimage",
          path: img,
          properties: { altText: p.name }
        }))
      },
      availability: "ON_HAND",
      deliveryEstimate: "TRANSIT"
    }));

    res.json(dtos);
  } catch (err) {
    console.error("Error fetching products:", err);
    res.status(500).json({ message: "Server Error" });
  }
});


app.listen(PORT, "0.0.0.0", () => {
  console.log(`Mock API running on http://0.0.0.0:${PORT}`);
});
