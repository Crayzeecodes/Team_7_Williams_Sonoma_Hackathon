const cors = require("cors");
const dotenv = require("dotenv");
const express = require("express");
const fs = require("fs");
const http = require("http");
const jwt = require("jsonwebtoken");
const mongoose = require("mongoose");
const path = require("path");
const { Server } = require("socket.io");
const auth = require("./middleware/auth");
const Product = require("./models/Product");
const User = require("./models/User");
const registryRoutes = require("./routes/registry");
const { initializeRegistrySocket } = require("./socket/registrySocket");

dotenv.config();

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST", "DELETE"],
  },
});

const PORT = Number(process.env.PORT || 3001);
const MONGODB_URI = process.env.MONGODB_URI || process.env.MONGO_URI || "mongodb://127.0.0.1:27017/ws_hackathon";
const JWT_SECRET = process.env.JWT_SECRET || "hackathon-secret";

initializeRegistrySocket(io);

app.use(cors());
app.use(express.json());
app.use("/images", express.static(path.join(__dirname, "images")));

function readJson(fileName) {
  const filePath = path.join(__dirname, "responses", fileName);
  return JSON.parse(fs.readFileSync(filePath, "utf8"));
}

function delayedJson(res, fileName, status = 200, delay = 250) {
  setTimeout(() => {
    res.status(status).json(readJson(fileName));
  }, delay);
}

function mapSkuToProduct(sku) {
  const price = Number(sku?.price?.sellingPrice || sku?.price?.regularPrice || 0);
  const images = (sku?.media?.images || []).map((image) => image.path).filter(Boolean);
  const properties = sku?.properties || {};
  const specs = [];

  Object.entries(properties).forEach(([key, value]) => {
    if (value !== undefined && value !== null && value !== "") {
      specs.push(`${key}: ${value}`);
    }
  });

  return {
    skuId: String(sku.id),
    name: sku.name || sku.shortName || "Williams Sonoma Product",
    description: `Availability: ${sku.availability || "unknown"} | Delivery: ${sku.deliveryEstimate || "unknown"}`,
    price,
    images,
    category: properties.productType || properties.pattern || "general",
    specs,
    stars: 4.5,
    reviews: [],
    arModelUrl: "",
    arScale: 1,
    arPlacementType: "floor",
  };
}

async function seedProductsIfNeeded() {
  const existingCount = await Product.countDocuments();
  if (existingCount > 0) {
    return;
  }

  const skuPayload = readJson("skus.json");
  const products = skuPayload.map(mapSkuToProduct);
  if (products.length > 0) {
    await Product.insertMany(products, { ordered: false });
  }
}

async function ensureUser({ email, password, name }) {
  let user = await User.findOne({ email });
  if (!user) {
    user = await User.create({
      email,
      password,
      name,
      addresses: [],
      createdAt: new Date(),
    });
  }
  return user;
}

async function ensureDemoUser() {
  return ensureUser({
    email: "demo@hackathon.com",
    password: "123456",
    name: "Demo User",
  });
}

function issueToken(user) {
  return jwt.sign({ userId: String(user._id) }, JWT_SECRET, {
    expiresIn: "7d",
  });
}

function serializeUser(user) {
  return {
    id: String(user._id),
    email: user.email,
    name: user.name,
  };
}

app.get("/health", (req, res) => {
  res.json({ status: "ok" });
});

app.post("/auth/register", async (req, res) => {
  try {
    const name = String(req.body?.name || "").trim();
    const email = String(req.body?.email || "").trim().toLowerCase();
    const password = String(req.body?.password || "");

    if (!name || !email || !password) {
      return res.status(400).json({ message: "name, email, and password are required" });
    }

    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(409).json({ message: "User already exists" });
    }

    const user = await User.create({
      email,
      password,
      name,
      addresses: [],
      createdAt: new Date(),
    });

    return res.status(201).json({
      token: issueToken(user),
      user: serializeUser(user),
    });
  } catch (error) {
    return res.status(500).json({ message: error.message || "Registration failed" });
  }
});

app.post("/auth/login", async (req, res) => {
  try {
    const email = String(req.body?.email || "").trim().toLowerCase();
    const password = String(req.body?.password || "");

    const user = await User.findOne({ email });
    if (!user || user.password !== password) {
      return res.status(401).json({ message: "Invalid credentials" });
    }

    return res.json({
      token: issueToken(user),
      user: serializeUser(user),
    });
  } catch (error) {
    return res.status(500).json({ message: error.message || "Login failed" });
  }
});

app.post("/login", async (req, res) => {
  try {
    const email = String(req.body?.email || "").trim().toLowerCase();
    const password = String(req.body?.password || "");

    if (email !== "demo@hackathon.com" || password !== "123456") {
      return delayedJson(res, "error_401.json", 401, 200);
    }

    const user = await ensureDemoUser();
    return res.json({
      token: issueToken(user),
      user: serializeUser(user),
    });
  } catch (error) {
    return res.status(500).json({ message: error.message || "Login failed" });
  }
});

app.get("/profile", (req, res) => {
  return delayedJson(res, "profile.json", 200, 300);
});

app.get("/feed", (req, res) => {
  return delayedJson(res, "feed.json", 200, 350);
});

app.get("/skus", async (req, res) => {
  try {
    const products = await Product.find({}).lean();
    if (products.length > 0) {
      return res.json(
        products.map((product) => ({
          id: product.skuId,
          name: product.name,
          shortName: product.name,
          primaryGroupId: product.skuId,
          price: {
            regularPrice: product.price,
            surcharge: 0,
            retailPrice: product.price,
            sellingPrice: product.price,
            monogramOrPersonalizationPrice: 0,
          },
          properties: {
            brand: "williams-sonoma",
            productType: product.category,
            allProductTypes: product.category,
            canGiftWrap: "true",
            isShoppable: "true",
            name: product.name,
            shortName: product.name,
          },
          media: {
            images: (product.images || []).map((imagePath) => ({
              type: "prodimage",
              path: imagePath,
              aspect: "q",
              properties: {
                altText: product.name,
              },
            })),
          },
          availability: "ON_HAND",
          deliveryEstimate: "TRANSIT",
        }))
      );
    }

    return delayedJson(res, "skus.json", 200, 300);
  } catch (error) {
    return res.status(500).json({ message: error.message || "Failed to load skus" });
  }
});

app.use("/api/registry", auth, registryRoutes);

async function start() {
  await mongoose.connect(MONGODB_URI);
  await seedProductsIfNeeded();
  await ensureDemoUser();

  server.listen(PORT, "0.0.0.0", () => {
    console.log(`Mock API running on http://0.0.0.0:${PORT}`);
  });
}

start().catch((error) => {
  console.error("Failed to start server", error);
  process.exit(1);
});
