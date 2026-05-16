const express = require("express");
const crypto = require("crypto");
const path = require("path");
const fs = require("fs");
const router = express.Router();
const mongoose = require("mongoose");

const Registry = require("../models/Registry");
const auth = require("../middleware/auth");
const { getGrokSuggestions } = require("../services/grokService");
const {
  emitCartUpdated,
  emitMemberJoined,
  emitMemberLeft,
  emitBudgetUpdated,
  emitRegistryCreated,
} = require("../socket/registrySocket");

// ─── In-Memory Fallback Store (for Hackathon resilience) ──────────────────────
const memoryRegistries = [];

function getModel() {
  return mongoose.connection.readyState === 1 ? Registry : null;
}

// ─── Helpers ───────────────────────────────────────────────────────────────────

function generateJoinCode() {
  return crypto.randomBytes(3).toString("hex").toUpperCase(); // 6-char uppercase hex
}

/**
 * Load product inventory from local JSON file (mock).
 * In production this would hit a database or product service.
 */
function loadProducts() {
  try {
    const filePath = path.join(__dirname, "../responses/skus.json");
    const raw = fs.readFileSync(filePath, "utf8");
    return JSON.parse(raw);
  } catch {
    return [];
  }
}

// ─── POST /api/registry — Create registry ──────────────────────────────────────

router.post("/", auth, async (req, res) => {
  try {
    const user = req.user;
    const {
      name,
      registryType,
      creatorName,
      eventType,
      eventDate,
      currency,
      eventDetails,
      giftingDetails,
      shippingAddress,
    } = req.body;

    if (!name || !registryType) {
      return res.status(400).json({ error: "name and registryType are required" });
    }

    // Generate unique joinCode (retry on collision if DB is up)
    let joinCode;
    let attempts = 0;
    const Model = getModel();
    do {
      joinCode = generateJoinCode();
      attempts++;
      if (Model) {
        const existing = await Model.findOne({ joinCode });
        if (!existing) break;
      } else {
        // In memory check
        const existing = memoryRegistries.find(r => r.joinCode === joinCode);
        if (!existing) break;
      }
    } while (attempts < 10);

    if (Model) {
      const registry = new Model({
        adminId: user.id,
        name,
        joinCode,
        registryType,
        creatorName: creatorName || user.name,
        eventType: eventType || "other",
        eventDate: eventDate ? new Date(eventDate) : undefined,
        currency: currency || { code: "USD", symbol: "$" },
        eventDetails: eventDetails || {},
        giftingDetails: giftingDetails || {},
        members: [
          {
            userId: user.id,
            role: "admin",
            contributedBudget: giftingDetails?.creatorBudget || 0,
            joinedAt: new Date(),
          },
        ],
        shippingAddress: shippingAddress || {},
      });

      registry.recalculateBudget();
      await registry.save();
      emitRegistryCreated(registry);
      return res.status(201).json(registry);
    } else {
      // Fallback to memory
      const registry = {
        _id: "mem_" + Date.now(),
        adminId: user.id,
        name,
        joinCode,
        registryType,
        creatorName: creatorName || user.name,
        eventType: eventType || "other",
        eventDate: eventDate ? new Date(eventDate) : undefined,
        currency: currency || { code: "USD", symbol: "$" },
        eventDetails: eventDetails || {},
        giftingDetails: giftingDetails || {},
        members: [
          {
            userId: user.id,
            role: "admin",
            contributedBudget: giftingDetails?.creatorBudget || 0,
            joinedAt: new Date(),
          },
        ],
        cartItems: [],
        aiSuggestions: [],
        budgetSnapshot: {
            totalBudget: eventDetails?.targetBudget || giftingDetails?.pooledBudget || 0,
            spentAmount: 0,
            remainingAmount: eventDetails?.targetBudget || giftingDetails?.pooledBudget || 0
        }
      };
      memoryRegistries.push(registry);
      emitRegistryCreated(registry);
      return res.status(201).json(registry);
    }
  } catch (err) {
    console.error("Create registry error:", err);
    res.status(500).json({ error: err.message });
  }
});

// ─── GET /api/registry — All registries for current user ───────────────────────

router.get("/", auth, async (req, res) => {
  try {
    const userId = req.user.id;
    const Model = getModel();
    
    if (Model) {
      const registries = await Model.find({
        $or: [{ adminId: userId }, { "members.userId": userId }],
      }).sort({ eventDate: 1 });
      return res.json(registries);
    } else {
      const registries = memoryRegistries.filter(r => 
        r.adminId === userId || r.members.some(m => m.userId === userId)
      );
      return res.json(registries);
    }
  } catch (err) {
    console.error("List registries error:", err);
    res.status(500).json({ error: err.message });
  }
});

// ─── GET /api/registry/:id — Single registry detail ───────────────────────────

router.get("/:id", auth, async (req, res) => {
  try {
    const registry = await Registry.findById(req.params.id);
    if (!registry) {
      return res.status(404).json({ error: "Registry not found" });
    }
    res.json(registry);
  } catch (err) {
    console.error("Get registry error:", err);
    res.status(500).json({ error: err.message });
  }
});

// ─── POST /api/registry/join — Join by joinCode ───────────────────────────────

router.post("/join", auth, async (req, res) => {
  try {
    const user = req.user;
    const { joinCode, contributedBudget } = req.body;

    if (!joinCode || joinCode.length !== 6) {
      return res.status(400).json({ error: "A valid 6-character join code is required" });
    }

    const registry = await Registry.findOne({ joinCode: joinCode.toUpperCase() });
    if (!registry) {
      return res.status(404).json({ error: "Registry not found with that code" });
    }

    // Already a member?
    const alreadyMember = registry.members.some((m) => m.userId === user.id);
    if (alreadyMember) {
      return res.status(409).json({ error: "You are already a member of this registry" });
    }

    // Dutch gifting: require contributedBudget
    if (
      registry.registryType === "gifting" &&
      registry.giftingDetails?.splitType === "dutch"
    ) {
      if (contributedBudget === undefined || contributedBudget === null) {
        return res.status(400).json({
          error: "This is a Dutch gifting registry. Please provide your contributedBudget.",
          requiresBudget: true,
          currency: registry.currency,
        });
      }
      // Add to pooled budget
      registry.giftingDetails.pooledBudget =
        (registry.giftingDetails.pooledBudget || 0) + Number(contributedBudget);
    }

    const newMember = {
      userId: user.id,
      role: "collaborator",
      contributedBudget: Number(contributedBudget) || 0,
      joinedAt: new Date(),
    };

    registry.members.push(newMember);
    registry.recalculateBudget();
    await registry.save();

    emitMemberJoined(String(registry._id), newMember);
    emitBudgetUpdated(String(registry._id), registry.budgetSnapshot);

    res.json(registry);
  } catch (err) {
    console.error("Join registry error:", err);
    res.status(500).json({ error: err.message });
  }
});

// ─── DELETE /api/registry/:id/leave — Leave registry ─────────────────────────

router.delete("/:id/leave", auth, async (req, res) => {
  try {
    const user = req.user;
    const registry = await Registry.findById(req.params.id);
    if (!registry) {
      return res.status(404).json({ error: "Registry not found" });
    }

    const memberIndex = registry.members.findIndex((m) => m.userId === user.id);
    if (memberIndex === -1) {
      return res.status(404).json({ error: "You are not a member of this registry" });
    }

    const leavingMember = registry.members[memberIndex];
    registry.members.splice(memberIndex, 1);

    // If leaving admin was the only member — delete registry
    if (registry.members.length === 0) {
      await Registry.findByIdAndDelete(req.params.id);
      emitMemberLeft(String(registry._id), user.id);
      return res.json({ deleted: true });
    }

    // If leaving member was the admin — transfer admin to first remaining member
    if (registry.adminId === user.id) {
      registry.adminId = registry.members[0].userId;
      registry.members[0].role = "admin";
    }

    // If dutch gifting, subtract contributed budget from pool
    if (
      registry.registryType === "gifting" &&
      registry.giftingDetails?.splitType === "dutch"
    ) {
      registry.giftingDetails.pooledBudget = Math.max(
        0,
        (registry.giftingDetails.pooledBudget || 0) - (leavingMember.contributedBudget || 0)
      );
    }

    registry.recalculateBudget();
    await registry.save();

    emitMemberLeft(String(registry._id), user.id);
    emitBudgetUpdated(String(registry._id), registry.budgetSnapshot);

    res.json({ success: true });
  } catch (err) {
    console.error("Leave registry error:", err);
    res.status(500).json({ error: err.message });
  }
});

// ─── POST /api/registry/:id/cart — Add item to cart ──────────────────────────

router.post("/:id/cart", auth, async (req, res) => {
  try {
    const user = req.user;
    const registry = await Registry.findById(req.params.id);
    if (!registry) {
      return res.status(404).json({ error: "Registry not found" });
    }

    const { productId, quantity, price, name, imageUrl, source } = req.body;
    if (!productId || !price || !name) {
      return res.status(400).json({ error: "productId, price, and name are required" });
    }

    // Increase quantity if same product already in cart
    const existingIndex = registry.cartItems.findIndex(
      (i) => i.productId === productId && i.status === "in_cart"
    );

    if (existingIndex !== -1) {
      registry.cartItems[existingIndex].quantity += Number(quantity) || 1;
    } else {
      registry.cartItems.push({
        productId,
        addedByUserId: user.id,
        quantity: Number(quantity) || 1,
        price: Number(price),
        name,
        imageUrl: imageUrl || "",
        source: source || "manual",
        status: "in_cart",
        addedAt: new Date(),
      });
    }

    registry.recalculateBudget();
    await registry.save();

    emitCartUpdated(String(registry._id), registry.cartItems, registry.budgetSnapshot);

    res.json({ cartItems: registry.cartItems, budgetSnapshot: registry.budgetSnapshot });
  } catch (err) {
    console.error("Add to cart error:", err);
    res.status(500).json({ error: err.message });
  }
});

// ─── DELETE /api/registry/:id/cart/:itemId — Remove cart item ────────────────

router.delete("/:id/cart/:itemId", auth, async (req, res) => {
  try {
    const registry = await Registry.findById(req.params.id);
    if (!registry) {
      return res.status(404).json({ error: "Registry not found" });
    }

    const itemIndex = registry.cartItems.findIndex(
      (i) => String(i._id) === req.params.itemId
    );
    if (itemIndex === -1) {
      return res.status(404).json({ error: "Cart item not found" });
    }

    registry.cartItems.splice(itemIndex, 1);
    registry.recalculateBudget();
    await registry.save();

    emitCartUpdated(String(registry._id), registry.cartItems, registry.budgetSnapshot);

    res.json({ cartItems: registry.cartItems, budgetSnapshot: registry.budgetSnapshot });
  } catch (err) {
    console.error("Remove cart item error:", err);
    res.status(500).json({ error: err.message });
  }
});

// ─── POST /api/registry/:id/suggest — AI suggestions via Grok ────────────────

router.post("/:id/suggest", auth, async (req, res) => {
  try {
    const registry = await Registry.findById(req.params.id);
    if (!registry) {
      return res.status(404).json({ error: "Registry not found" });
    }

    const products = loadProducts();
    const suggestions = await getGrokSuggestions(registry, products);

    registry.aiSuggestions = suggestions;
    await registry.save();

    // Enrich suggestions with product details from inventory
    const enriched = suggestions.map((s) => {
      const product = products.find((p) => String(p.id || p._id) === s.productId);
      return {
        ...s,
        product: product
          ? {
              id: product.id,
              name: product.name,
              price: product.price?.regularPrice || product.price?.sellingPrice || 0,
              imageUrl: product.media?.images?.[0]?.path || "",
              category: product.properties?.productType || "",
            }
          : null,
      };
    });

    res.json({ suggestions: enriched });
  } catch (err) {
    console.error("AI suggest error:", err);
    res.status(500).json({ error: err.message });
  }
});

// ─── GET /api/registry/:id/members — Members list ────────────────────────────

router.get("/:id/members", auth, async (req, res) => {
  try {
    const registry = await Registry.findById(req.params.id);
    if (!registry) {
      return res.status(404).json({ error: "Registry not found" });
    }
    res.json({ members: registry.members });
  } catch (err) {
    console.error("Get members error:", err);
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
