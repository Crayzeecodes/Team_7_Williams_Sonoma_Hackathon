const crypto = require("crypto");

const state = {
  users: [],
  registries: [],
  products: [],
};

function createId() {
  return crypto.randomUUID();
}

function setProducts(products) {
  state.products = products.map((product, index) => ({
    _id: product._id || product.skuId || `product-${index + 1}`,
    skuId: String(product.skuId || index + 1),
    name: product.name,
    description: product.description || "",
    price: Number(product.price || 0),
    images: Array.isArray(product.images) ? product.images : [],
    category: product.category || "general",
    specs: Array.isArray(product.specs) ? product.specs : [],
    stars: Number(product.stars || 0),
    reviews: Array.isArray(product.reviews) ? product.reviews : [],
    arModelUrl: product.arModelUrl || "",
    arScale: Number(product.arScale || 1),
    arPlacementType: product.arPlacementType || "floor",
  }));
}

function getProducts() {
  return state.products;
}

function findProduct(identifier) {
  const normalized = String(identifier || "");
  return state.products.find(
    (product) => String(product._id) === normalized || String(product.skuId) === normalized
  );
}

function findUserByEmail(email) {
  const normalized = String(email || "").trim().toLowerCase();
  return state.users.find((user) => user.email === normalized) || null;
}

function findUserById(id) {
  return state.users.find((user) => String(user._id) === String(id)) || null;
}

function createUser({ email, password, name }) {
  const user = {
    _id: createId(),
    email: String(email || "").trim().toLowerCase(),
    password: String(password || ""),
    name: String(name || "").trim() || "Williams Sonoma Guest",
    addresses: [],
    createdAt: new Date(),
  };
  state.users.push(user);
  return user;
}

function ensureUser({ email, password, name }) {
  const existing = findUserByEmail(email);
  if (existing) {
    if (name && existing.name !== name) {
      existing.name = name;
    }
    if (password && !existing.password) {
      existing.password = password;
    }
    return existing;
  }

  return createUser({ email, password, name });
}

function getRegistries() {
  return state.registries;
}

function findRegistryById(id) {
  return state.registries.find((registry) => String(registry._id) === String(id)) || null;
}

function findRegistryByJoinCode(joinCode) {
  const normalized = String(joinCode || "").trim().toUpperCase();
  return state.registries.find((registry) => registry.joinCode === normalized) || null;
}

function saveRegistry(registry) {
  const index = state.registries.findIndex((item) => String(item._id) === String(registry._id));
  if (index >= 0) {
    state.registries[index] = registry;
  } else {
    state.registries.push(registry);
  }
  return registry;
}

function deleteRegistry(id) {
  const index = state.registries.findIndex((registry) => String(registry._id) === String(id));
  if (index >= 0) {
    state.registries.splice(index, 1);
    return true;
  }
  return false;
}

module.exports = {
  createId,
  setProducts,
  getProducts,
  findProduct,
  findUserByEmail,
  findUserById,
  createUser,
  ensureUser,
  getRegistries,
  findRegistryById,
  findRegistryByJoinCode,
  saveRegistry,
  deleteRegistry,
};
