const crypto = require("crypto");
const express = require("express");
const mongoose = require("mongoose");
const Registry = require("../models/Registry");
const Product = require("../models/Product");
const { fetchGrokSuggestions } = require("../services/grokService");
const { emitRegistryCreated, emitToRegistry } = require("../socket/registrySocket");

const router = express.Router();

function isObjectId(value) {
  return mongoose.Types.ObjectId.isValid(String(value));
}

async function generateJoinCode() {
  for (let attempt = 0; attempt < 10; attempt += 1) {
    const joinCode = crypto.randomBytes(4).toString("hex").slice(0, 6).toUpperCase();
    const existing = await Registry.exists({ joinCode });
    if (!existing) {
      return joinCode;
    }
  }
  throw new Error("Unable to generate unique join code");
}

function getTotalBudget(registry) {
  if (registry.registryType === "event") {
    return Number(registry.eventDetails?.targetBudget || 0);
  }

  if (registry.giftingDetails?.splitType === "dutch") {
    return Number(registry.giftingDetails?.pooledBudget || 0);
  }

  return Number(registry.giftingDetails?.creatorBudget || 0);
}

function getSpentAmount(registry) {
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
  const totalBudget = getTotalBudget(registry);
  const spentAmount = getSpentAmount(registry);
  registry.budgetSnapshot = {
    totalBudget,
    spentAmount,
    remainingAmount: Math.max(0, totalBudget - spentAmount),
    lastUpdated: new Date(),
  };
}

function toMemberPayload(member) {
  return {
    userId: String(member.userId?._id || member.userId),
    name: member.userId?.name || undefined,
    email: member.userId?.email || undefined,
    role: member.role,
    contributedBudget: Number(member.contributedBudget || 0),
    joinedAt: member.joinedAt,
  };
}

async function getRegistryForUser(registryId, userId) {
  return Registry.findOne({
    _id: registryId,
    $or: [{ adminId: userId }, { "members.userId": userId }],
  });
}

router.post("/", async (req, res) => {
  try {
    const joinCode = await generateJoinCode();
    const userId = req.user._id;

    const registry = new Registry({
      ...req.body,
      adminId: userId,
      joinCode,
      members: [
        {
          userId,
          role: "admin",
          contributedBudget:
            req.body.registryType === "gifting"
              ? Number(req.body.giftingDetails?.creatorBudget || 0)
              : 0,
          joinedAt: new Date(),
        },
      ],
      createdAt: new Date(),
    });

    recalculateBudget(registry);
    await registry.save();

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
      const registry = await Registry.findOne({ joinCode }).select(
        "name joinCode registryType creatorName eventType eventDate currency giftingDetails.budgetStatus giftingDetails.splitType"
      );

      if (!registry) {
        return res.status(404).json({ message: "Registry not found" });
      }

      return res.json(registry);
    }

    const registries = await Registry.find({
      $or: [{ adminId: req.user._id }, { "members.userId": req.user._id }],
    }).sort({ eventDate: 1 });

    return res.json(registries);
  } catch (error) {
    return res.status(500).json({ message: error.message || "Failed to load registries" });
  }
});

router.get("/:id", async (req, res) => {
  try {
    const registry = await Registry.findOne({
      _id: req.params.id,
      $or: [{ adminId: req.user._id }, { "members.userId": req.user._id }],
    })
      .populate("members.userId", "name email")
      .populate("cartItems.productId")
      .populate("cartItems.addedByUserId", "name email")
      .populate("aiSuggestions.productId");

    if (!registry) {
      return res.status(404).json({ message: "Registry not found" });
    }

    return res.json(registry);
  } catch (error) {
    return res.status(500).json({ message: error.message || "Failed to load registry" });
  }
});

router.post("/join", async (req, res) => {
  try {
    const joinCode = String(req.body.joinCode || "").trim().toUpperCase();
    const contributedBudget = Number(req.body.contributedBudget || 0);
    const registry = await Registry.findOne({ joinCode }).populate("members.userId", "name email");

    if (!registry) {
      return res.status(404).json({ message: "Registry not found" });
    }

    const alreadyMember = (registry.members || []).some(
      (member) => String(member.userId?._id || member.userId) === String(req.user._id)
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
      userId: req.user._id,
      role: "collaborator",
      contributedBudget:
        registry.registryType === "gifting" && registry.giftingDetails?.splitType === "dutch"
          ? contributedBudget
          : 0,
      joinedAt: new Date(),
    };

    registry.members.push(member);
    recalculateBudget(registry);
    await registry.save();
    await registry.populate("members.userId", "name email");

    const joinedMember = registry.members.find(
      (item) => String(item.userId?._id || item.userId) === String(req.user._id)
    );

    emitToRegistry(registry._id, "registry:memberJoined", {
      registryId: String(registry._id),
      member: toMemberPayload(joinedMember),
    });
    emitToRegistry(registry._id, "registry:budgetUpdated", {
      registryId: String(registry._id),
      budgetSnapshot: registry.budgetSnapshot,
    });

    return res.status(200).json(registry);
  } catch (error) {
    return res.status(500).json({ message: error.message || "Failed to join registry" });
  }
});

router.delete("/:id/leave", async (req, res) => {
  try {
    const registry = await getRegistryForUser(req.params.id, req.user._id);
    if (!registry) {
      return res.status(404).json({ message: "Registry not found" });
    }

    const leavingUserId = String(req.user._id);
    const wasAdmin = String(registry.adminId) === leavingUserId;

    registry.members = (registry.members || []).filter(
      (member) => String(member.userId) !== leavingUserId
    );

    if (wasAdmin) {
      const nextAdmin = registry.members[0];
      if (!nextAdmin) {
        await Registry.deleteOne({ _id: registry._id });
        emitToRegistry(registry._id, "registry:memberLeft", {
          registryId: String(registry._id),
          userId: leavingUserId,
        });
        return res.json({ deleted: true, registryId: String(registry._id) });
      }

      registry.adminId = nextAdmin.userId;
      registry.members = registry.members.map((member, index) => ({
        ...member.toObject ? member.toObject() : member,
        role: index === 0 ? "admin" : "collaborator",
      }));
    }

    recalculateBudget(registry);
    await registry.save();

    emitToRegistry(registry._id, "registry:memberLeft", {
      registryId: String(registry._id),
      userId: leavingUserId,
    });
    emitToRegistry(registry._id, "registry:budgetUpdated", {
      registryId: String(registry._id),
      budgetSnapshot: registry.budgetSnapshot,
    });

    return res.json({ deleted: false, registry });
  } catch (error) {
    return res.status(500).json({ message: error.message || "Failed to leave registry" });
  }
});

router.post("/:id/cart", async (req, res) => {
  try {
    const registry = await getRegistryForUser(req.params.id, req.user._id);
    if (!registry) {
      return res.status(404).json({ message: "Registry not found" });
    }

    const quantity = Math.max(1, Number(req.body.quantity || 1));
    const source = req.body.source === "ai" ? "ai" : "manual";
    const status = req.body.status === "purchased" ? "purchased" : "in_cart";

    let product = null;
    if (isObjectId(req.body.productId)) {
      product = await Product.findById(req.body.productId);
    } else if (req.body.productId) {
      product = await Product.findOne({ skuId: String(req.body.productId) });
    }

    if (!product) {
      return res.status(404).json({ message: "Product not found" });
    }

    const existingItem = registry.cartItems.find(
      (item) =>
        String(item.productId) === String(product._id) &&
        String(item.addedByUserId) === String(req.user._id) &&
        item.status === "in_cart"
    );

    if (existingItem) {
      existingItem.quantity += quantity;
      existingItem.price = Number(req.body.price || product.price);
      existingItem.source = source;
    } else {
      registry.cartItems.push({
        productId: product._id,
        addedByUserId: req.user._id,
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
    await registry.save();
    await registry.populate("cartItems.productId");
    await registry.populate("cartItems.addedByUserId", "name email");

    const payload = {
      registryId: String(registry._id),
      cartItems: registry.cartItems,
      budgetSnapshot: registry.budgetSnapshot,
    };

    emitToRegistry(registry._id, "registry:cartUpdated", payload);
    emitToRegistry(registry._id, "registry:budgetUpdated", {
      registryId: String(registry._id),
      budgetSnapshot: registry.budgetSnapshot,
    });

    return res.status(201).json(payload);
  } catch (error) {
    return res.status(500).json({ message: error.message || "Failed to add cart item" });
  }
});

router.delete("/:id/cart/:itemId", async (req, res) => {
  try {
    const registry = await getRegistryForUser(req.params.id, req.user._id);
    if (!registry) {
      return res.status(404).json({ message: "Registry not found" });
    }

    const item = registry.cartItems.id(req.params.itemId);
    if (!item) {
      return res.status(404).json({ message: "Cart item not found" });
    }

    const isAdmin = String(registry.adminId) === String(req.user._id);
    const isOwner = String(item.addedByUserId) === String(req.user._id);
    if (!isAdmin && !isOwner) {
      return res.status(403).json({ message: "Not allowed to remove this cart item" });
    }

    item.deleteOne();
    recalculateBudget(registry);
    await registry.save();

    const payload = {
      registryId: String(registry._id),
      cartItems: registry.cartItems,
      budgetSnapshot: registry.budgetSnapshot,
    };

    emitToRegistry(registry._id, "registry:cartUpdated", payload);
    emitToRegistry(registry._id, "registry:budgetUpdated", {
      registryId: String(registry._id),
      budgetSnapshot: registry.budgetSnapshot,
    });

    return res.json(payload);
  } catch (error) {
    return res.status(500).json({ message: error.message || "Failed to remove cart item" });
  }
});

router.post("/:id/suggest", async (req, res) => {
  try {
    const registry = await getRegistryForUser(req.params.id, req.user._id);
    if (!registry) {
      return res.status(404).json({ message: "Registry not found" });
    }

    const forceRefresh = Boolean(req.body.forceRefresh);
    if (!forceRefresh && Array.isArray(registry.aiSuggestions) && registry.aiSuggestions.length > 0) {
      await registry.populate("aiSuggestions.productId");
      return res.json(registry.aiSuggestions.slice(0, 8));
    }

    const products = await Product.find({}).limit(200);
    if (!products.length) {
      return res.status(404).json({ message: "No products available for suggestions" });
    }

    const suggestions = await fetchGrokSuggestions(registry, products);
    registry.aiSuggestions = suggestions;
    await registry.save();
    await registry.populate("aiSuggestions.productId");

    return res.json(registry.aiSuggestions.slice(0, 8));
  } catch (error) {
    return res.status(500).json({ message: error.message || "Failed to generate suggestions" });
  }
});

router.get("/:id/members", async (req, res) => {
  try {
    const registry = await Registry.findOne({
      _id: req.params.id,
      $or: [{ adminId: req.user._id }, { "members.userId": req.user._id }],
    }).populate("members.userId", "name email");

    if (!registry) {
      return res.status(404).json({ message: "Registry not found" });
    }

    const members = (registry.members || []).map((member) => ({
      userId: String(member.userId?._id || member.userId),
      name: member.userId?.name || "Unknown User",
      joinedAt: member.joinedAt,
      contributedBudget: Number(member.contributedBudget || 0),
      role: member.role,
    }));

    return res.json(members);
  } catch (error) {
    return res.status(500).json({ message: error.message || "Failed to load members" });
  }
});

module.exports = router;
