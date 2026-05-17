const crypto = require("crypto");
const express = require("express");
const memoryStore = require("../services/memoryStore");
const { emitRegistryCreated, emitToRegistry } = require("../socket/registrySocket");

const router = express.Router();

function randomScore(seed) {
  const digest = crypto.createHash("sha1").update(seed).digest("hex");
  return 0.7 + (parseInt(digest.slice(0, 2), 16) / 255) * 0.29;
}

function toUserSummary(user) {
  return {
    _id: String(user._id),
    email: user.email,
    name: user.name,
  };
}

function cloneProduct(product) {
  return {
    _id: String(product._id),
    skuId: String(product.skuId),
    name: product.name,
    description: product.description || "",
    price: Number(product.price || 0),
    images: Array.isArray(product.images) ? [...product.images] : [],
    category: product.category || "general",
    specs: Array.isArray(product.specs) ? [...product.specs] : [],
    stars: Number(product.stars || 0),
    reviews: Array.isArray(product.reviews) ? [...product.reviews] : [],
    arModelUrl: product.arModelUrl || "",
    arScale: Number(product.arScale || 1),
    arPlacementType: product.arPlacementType || "floor",
  };
}

function totalBudget(registry) {
  if (registry.registryType === "event") {
    return Number(registry.eventDetails?.targetBudget || 0);
  }
  if (registry.giftingDetails?.splitType === "dutch") {
    return Number(registry.giftingDetails?.pooledBudget || 0);
  }
  return Number(registry.giftingDetails?.creatorBudget || 0);
}

function spentAmount(registry) {
  return (registry.cartItems || []).reduce((total, item) => {
    if (item.status !== "in_cart") {
      return total;
    }
    return total + Number(item.price || 0) * Number(item.quantity || 0);
  }, 0);
}

function updateDutchBudgetState(registry) {
  if (registry.registryType !== "gifting" || registry.giftingDetails?.splitType !== "dutch") {
    return;
  }

  const pooledBudget = (registry.members || []).reduce(
    (total, member) => total + Number(member.contributedBudget || 0),
    0
  );

  registry.giftingDetails.pooledBudget = pooledBudget;

  const collaboratorMembers = (registry.members || []).filter((member) => member.role === "collaborator");
  const enoughCollaborators = collaboratorMembers.length >= Number(registry.giftingDetails?.collaboratorCount || 0);
  const everyoneBudgeted = collaboratorMembers.every((member) => Number(member.contributedBudget || 0) > 0);

  registry.giftingDetails.budgetStatus = enoughCollaborators && everyoneBudgeted ? "finalized" : "pending";
}

function recalculateBudget(registry) {
  updateDutchBudgetState(registry);
  const budget = totalBudget(registry);
  const spent = spentAmount(registry);
  registry.budgetSnapshot = {
    totalBudget: budget,
    spentAmount: spent,
    remainingAmount: Math.max(0, budget - spent),
    lastUpdated: new Date(),
  };
}

function generateJoinCode() {
  for (let attempt = 0; attempt < 10; attempt += 1) {
    const joinCode = crypto.randomBytes(4).toString("hex").slice(0, 6).toUpperCase();
    if (!memoryStore.findRegistryByJoinCode(joinCode)) {
      return joinCode;
    }
  }
  throw new Error("Unable to generate unique join code");
}

function userHasAccess(registry, userId) {
  return (
    String(registry.adminId) === String(userId) ||
    (registry.members || []).some((member) => String(member.userId._id) === String(userId))
  );
}

function ensureRegistryAccess(registryId, userId) {
  const registry = memoryStore.findRegistryById(registryId);
  if (!registry || !userHasAccess(registry, userId)) {
    return null;
  }
  return registry;
}

function createSuggestions(registry) {
  const preferredText = [
    registry.name,
    registry.creatorName,
    registry.registryType,
    registry.eventType,
    registry.eventDetails?.aiPlannerAnswers?.map((item) => item.answer).join(" "),
    registry.giftingDetails?.aiPlannerAnswers?.map((item) => item.answer).join(" "),
  ]
    .filter(Boolean)
    .join(" ")
    .toLowerCase();

  const products = memoryStore.getProducts();
  const scored = products.map((product) => {
    const categoryMatch = preferredText.includes(String(product.category || "").toLowerCase()) ? 0.15 : 0;
    const score = Math.min(0.99, randomScore(`${registry._id}-${product._id}`) + categoryMatch);
    return {
      productId: cloneProduct(product),
      score: Number(score.toFixed(2)),
      reasoning: `Selected for ${registry.name} based on budget, category, and gifting fit.`,
      generatedAt: new Date(),
    };
  });

  return scored.sort((a, b) => b.score - a.score).slice(0, 8);
}

router.post("/", async (req, res) => {
  try {
    const joinCode = generateJoinCode();
    const user = req.user;
    const registry = {
      _id: memoryStore.createId(),
      adminId: String(user._id),
      name: req.body.name,
      joinCode,
      registryType: req.body.registryType,
      creatorName: req.body.creatorName,
      eventType: req.body.eventType,
      eventDate: req.body.eventDate ? new Date(req.body.eventDate) : new Date(),
      currency: req.body.currency || { code: "USD", symbol: "$" },
      eventDetails: req.body.eventDetails || {
        aiPlannerAnswers: [],
        targetBudget: 0,
        paymentSplitType: "split",
      },
      giftingDetails: req.body.giftingDetails || {
        collaboratorCount: 1,
        aiPlannerAnswers: [],
        splitType: "split",
        creatorBudget: 0,
        pooledBudget: 0,
        budgetStatus: "pending",
      },
      members: [
        {
          userId: toUserSummary(user),
          role: "admin",
          contributedBudget:
            req.body.registryType === "gifting"
              ? Number(req.body.giftingDetails?.creatorBudget || 0)
              : 0,
          joinedAt: new Date(),
        },
      ],
      cartItems: [],
      aiSuggestions: [],
      polls: [],
      budgetSnapshot: req.body.budgetSnapshot || {
        totalBudget: 0,
        spentAmount: 0,
        remainingAmount: 0,
        lastUpdated: new Date(),
      },
      shippingAddress: req.body.shippingAddress || "",
      createdAt: new Date(),
    };

    recalculateBudget(registry);
    memoryStore.saveRegistry(registry);
    emitRegistryCreated(registry);
    return res.status(201).json(registry);
  } catch (error) {
    return res.status(500).json({ message: error.message || "Failed to create registry" });
  }
});

router.get("/", async (req, res) => {
  try {
    const joinCode = String(req.query.joinCode || "").trim().toUpperCase();
    if (joinCode) {
      const registry = memoryStore.findRegistryByJoinCode(joinCode);
      if (!registry) {
        return res.status(404).json({ message: "Registry not found" });
      }
      return res.json({
        _id: registry._id,
        name: registry.name,
        joinCode: registry.joinCode,
        registryType: registry.registryType,
        creatorName: registry.creatorName,
        eventType: registry.eventType,
        eventDate: registry.eventDate,
        currency: registry.currency,
        giftingDetails: {
          budgetStatus: registry.giftingDetails?.budgetStatus || "pending",
          splitType: registry.giftingDetails?.splitType || "split",
        },
      });
    }

    const registries = memoryStore
      .getRegistries()
      .filter((registry) => userHasAccess(registry, req.user._id))
      .sort((a, b) => new Date(a.eventDate) - new Date(b.eventDate));

    return res.json(registries);
  } catch (error) {
    return res.status(500).json({ message: error.message || "Failed to load registries" });
  }
});

router.get("/:id", async (req, res) => {
  const registry = ensureRegistryAccess(req.params.id, req.user._id);
  if (!registry) {
    return res.status(404).json({ message: "Registry not found" });
  }
  return res.json(registry);
});

router.post("/join", async (req, res) => {
  try {
    const joinCode = String(req.body.joinCode || "").trim().toUpperCase();
    const contributedBudget = Number(req.body.contributedBudget || 0);
    const registry = memoryStore.findRegistryByJoinCode(joinCode);

    if (!registry) {
      return res.status(404).json({ message: "Registry not found" });
    }

    const alreadyMember = (registry.members || []).some(
      (member) => String(member.userId._id) === String(req.user._id)
    );
    if (alreadyMember) {
      return res.status(409).json({ message: "User has already joined this registry" });
    }

    if (
      registry.registryType === "gifting" &&
      registry.giftingDetails?.splitType === "dutch" &&
      registry.giftingDetails?.budgetStatus === "pending" &&
      contributedBudget <= 0
    ) {
      return res.status(400).json({ message: "contributedBudget is required to join this registry" });
    }

    const member = {
      userId: toUserSummary(req.user),
      role: "collaborator",
      contributedBudget:
        registry.registryType === "gifting" && registry.giftingDetails?.splitType === "dutch"
          ? contributedBudget
          : 0,
      joinedAt: new Date(),
    };

    registry.members.push(member);
    recalculateBudget(registry);
    memoryStore.saveRegistry(registry);

    emitToRegistry(registry._id, "registry:memberJoined", {
      registryId: String(registry._id),
      member: {
        userId: member.userId._id,
        name: member.userId.name,
        joinedAt: member.joinedAt,
        contributedBudget: member.contributedBudget,
        role: member.role,
      },
    });

    return res.json(registry);
  } catch (error) {
    return res.status(500).json({ message: error.message || "Failed to join registry" });
  }
});

router.delete("/:id/leave", async (req, res) => {
  try {
    const registry = ensureRegistryAccess(req.params.id, req.user._id);
    if (!registry) {
      return res.status(404).json({ message: "Registry not found" });
    }

    const leavingUserId = String(req.user._id);
    const wasAdmin = String(registry.adminId) === leavingUserId;

    registry.members = (registry.members || []).filter(
      (member) => String(member.userId._id) !== leavingUserId
    );

    if (wasAdmin) {
      const nextAdmin = registry.members[0];
      if (!nextAdmin) {
        memoryStore.deleteRegistry(registry._id);
        emitToRegistry(registry._id, "registry:memberLeft", {
          registryId: String(registry._id),
          userId: leavingUserId,
        });
        return res.json({ deleted: true, registryId: String(registry._id) });
      }

      registry.adminId = String(nextAdmin.userId._id);
      registry.members = registry.members.map((member, index) => ({
        ...member,
        role: index === 0 ? "admin" : "collaborator",
      }));
    }

    recalculateBudget(registry);
    memoryStore.saveRegistry(registry);
    emitToRegistry(registry._id, "registry:memberLeft", {
      registryId: String(registry._id),
      userId: leavingUserId,
    });

    return res.json({ deleted: false, registry });
  } catch (error) {
    return res.status(500).json({ message: error.message || "Failed to leave registry" });
  }
});

router.post("/:id/cart", async (req, res) => {
  try {
    const registry = ensureRegistryAccess(req.params.id, req.user._id);
    if (!registry) {
      return res.status(404).json({ message: "Registry not found" });
    }

    const product = memoryStore.findProduct(req.body.productId);
    if (!product) {
      return res.status(404).json({ message: "Product not found" });
    }

    const quantity = Math.max(1, Number(req.body.quantity || 1));
    const source = req.body.source === "ai" ? "ai" : "manual";
    const status = req.body.status === "purchased" ? "purchased" : "in_cart";

    const existingItem = (registry.cartItems || []).find(
      (item) =>
        String(item.productId._id) === String(product._id) &&
        String(item.addedByUserId._id) === String(req.user._id) &&
        item.status === "in_cart"
    );

    if (existingItem) {
      existingItem.quantity += quantity;
      existingItem.price = Number(req.body.price || product.price);
      existingItem.source = source;
    } else {
      registry.cartItems.push({
        _id: memoryStore.createId(),
        productId: cloneProduct(product),
        addedByUserId: toUserSummary(req.user),
        quantity,
        price: Number(req.body.price || product.price),
        name: req.body.name || product.name,
        imageUrl: req.body.imageUrl || product.images?.[0] || "",
        source,
        status,
        addedAt: new Date(),
      });
    }

    recalculateBudget(registry);
    memoryStore.saveRegistry(registry);

    const payload = {
      registryId: String(registry._id),
      cartItems: registry.cartItems,
      budgetSnapshot: registry.budgetSnapshot,
    };

    emitToRegistry(registry._id, "registry:cartUpdated", payload);
    return res.status(201).json(payload);
  } catch (error) {
    return res.status(500).json({ message: error.message || "Failed to add cart item" });
  }
});

router.delete("/:id/cart/:itemId", async (req, res) => {
  try {
    const registry = ensureRegistryAccess(req.params.id, req.user._id);
    if (!registry) {
      return res.status(404).json({ message: "Registry not found" });
    }

    const item = (registry.cartItems || []).find((entry) => String(entry._id) === String(req.params.itemId));
    if (!item) {
      return res.status(404).json({ message: "Cart item not found" });
    }

    const isAdmin = String(registry.adminId) === String(req.user._id);
    const isOwner = String(item.addedByUserId._id) === String(req.user._id);
    if (!isAdmin && !isOwner) {
      return res.status(403).json({ message: "Not allowed to remove this cart item" });
    }

    registry.cartItems = registry.cartItems.filter((entry) => String(entry._id) !== String(req.params.itemId));
    recalculateBudget(registry);
    memoryStore.saveRegistry(registry);

    const payload = {
      registryId: String(registry._id),
      cartItems: registry.cartItems,
      budgetSnapshot: registry.budgetSnapshot,
    };

    emitToRegistry(registry._id, "registry:cartUpdated", payload);
    return res.json(payload);
  } catch (error) {
    return res.status(500).json({ message: error.message || "Failed to remove cart item" });
  }
});

router.post("/:id/suggest", async (req, res) => {
  try {
    const registry = ensureRegistryAccess(req.params.id, req.user._id);
    if (!registry) {
      return res.status(404).json({ message: "Registry not found" });
    }

    const forceRefresh = Boolean(req.body.forceRefresh);
    if (!forceRefresh && Array.isArray(registry.aiSuggestions) && registry.aiSuggestions.length > 0) {
      return res.json(registry.aiSuggestions.slice(0, 8));
    }

    registry.aiSuggestions = createSuggestions(registry);
    memoryStore.saveRegistry(registry);
    return res.json(registry.aiSuggestions.slice(0, 8));
  } catch (error) {
    return res.status(500).json({ message: error.message || "Failed to generate suggestions" });
  }
});

router.get("/:id/members", async (req, res) => {
  const registry = ensureRegistryAccess(req.params.id, req.user._id);
  if (!registry) {
    return res.status(404).json({ message: "Registry not found" });
  }

  const members = (registry.members || []).map((member) => ({
    userId: String(member.userId._id),
    name: member.userId.name || "Unknown User",
    joinedAt: member.joinedAt,
    contributedBudget: Number(member.contributedBudget || 0),
    role: member.role,
  }));

  return res.json(members);
});

module.exports = router;
