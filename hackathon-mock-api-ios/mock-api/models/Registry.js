const mongoose = require("mongoose");

// ─── Sub-schemas ───────────────────────────────────────────────────────────────

const ReviewSchema = new mongoose.Schema({
  userId: { type: String, required: true },
  rating: { type: Number, required: true, min: 1, max: 5 },
  comment: { type: String, default: "" },
  createdAt: { type: Date, default: Date.now },
});

const CartItemSchema = new mongoose.Schema({
  productId: { type: String, required: true },
  addedByUserId: { type: String, required: true },
  quantity: { type: Number, required: true, default: 1, min: 1 },
  price: { type: Number, required: true },
  name: { type: String, required: true },
  imageUrl: { type: String, default: "" },
  source: { type: String, enum: ["manual", "ai"], default: "manual" },
  status: { type: String, enum: ["in_cart", "purchased"], default: "in_cart" },
  addedAt: { type: Date, default: Date.now },
});

const MemberSchema = new mongoose.Schema({
  userId: { type: String, required: true },
  role: { type: String, enum: ["admin", "collaborator"], default: "collaborator" },
  contributedBudget: { type: Number, default: 0 },
  joinedAt: { type: Date, default: Date.now },
});

const AiSuggestionSchema = new mongoose.Schema({
  productId: { type: String, required: true },
  score: { type: Number, required: true, min: 0, max: 1 },
  reasoning: { type: String, default: "" },
  generatedAt: { type: Date, default: Date.now },
});

const PollOptionSchema = new mongoose.Schema({
  productId: { type: String, required: true },
  votes: [{ type: String }], // array of userId strings
});

const PollSchema = new mongoose.Schema({
  question: { type: String, required: true },
  options: [PollOptionSchema],
  status: { type: String, enum: ["active", "closed"], default: "active" },
  createdAt: { type: Date, default: Date.now },
});

const BudgetSnapshotSchema = new mongoose.Schema({
  totalBudget: { type: Number, default: 0 },
  spentAmount: { type: Number, default: 0 },
  remainingAmount: { type: Number, default: 0 },
  lastUpdated: { type: Date, default: Date.now },
});

const CurrencySchema = new mongoose.Schema({
  code: { type: String, default: "USD" },
  symbol: { type: String, default: "$" },
});

const EventDetailsSchema = new mongoose.Schema({
  aiPlannerAnswers: { type: [String], default: [] },
  targetBudget: { type: Number, default: 0 },
  paymentSplitType: { type: String, enum: ["split", "dutch"], default: "split" },
});

const GiftingDetailsSchema = new mongoose.Schema({
  collaboratorCount: { type: Number, default: 1 },
  aiPlannerAnswers: { type: [String], default: [] },
  splitType: { type: String, enum: ["split", "dutch"], default: "split" },
  creatorBudget: { type: Number, default: 0 },
  pooledBudget: { type: Number, default: 0 },
  budgetStatus: { type: String, enum: ["pending", "finalized"], default: "pending" },
});

const AddressSchema = new mongoose.Schema({
  street: { type: String, default: "" },
  city: { type: String, default: "" },
  state: { type: String, default: "" },
  zipCode: { type: String, default: "" },
});

// ─── Main Registry Schema ───────────────────────────────────────────────────────

const RegistrySchema = new mongoose.Schema(
  {
    adminId: { type: String, required: true },
    name: { type: String, required: true },
    joinCode: {
      type: String,
      required: true,
      unique: true,
      uppercase: true,
      minlength: 6,
      maxlength: 6,
    },
    registryType: {
      type: String,
      enum: ["event", "gifting"],
      required: true,
    },
    creatorName: { type: String, default: "" },
    eventType: {
      type: String,
      enum: [
        "birthday",
        "anniversary",
        "wedding",
        "baby_shower",
        "graduation",
        "housewarming",
        "farewell",
        "festival",
        "other",
      ],
      default: "other",
    },
    eventDate: { type: Date },
    currency: { type: CurrencySchema, default: () => ({}) },
    eventDetails: { type: EventDetailsSchema, default: () => ({}) },
    giftingDetails: { type: GiftingDetailsSchema, default: () => ({}) },
    members: { type: [MemberSchema], default: [] },
    cartItems: { type: [CartItemSchema], default: [] },
    aiSuggestions: { type: [AiSuggestionSchema], default: [] },
    polls: { type: [PollSchema], default: [] },
    budgetSnapshot: { type: BudgetSnapshotSchema, default: () => ({}) },
    shippingAddress: { type: AddressSchema, default: () => ({}) },
  },
  { timestamps: true }
);

// ─── Budget recalculation helper (called from routes) ──────────────────────────

RegistrySchema.methods.recalculateBudget = function () {
  const inCartItems = this.cartItems.filter((i) => i.status === "in_cart");
  const spent = inCartItems.reduce((sum, i) => sum + i.price * i.quantity, 0);

  let total = 0;
  if (this.registryType === "event") {
    total = this.eventDetails?.targetBudget ?? 0;
  } else if (this.giftingDetails?.splitType === "dutch") {
    total = this.giftingDetails?.pooledBudget ?? 0;
  } else {
    total = this.giftingDetails?.creatorBudget ?? 0;
  }

  this.budgetSnapshot = {
    totalBudget: total,
    spentAmount: Math.round(spent * 100) / 100,
    remainingAmount: Math.max(0, Math.round((total - spent) * 100) / 100),
    lastUpdated: new Date(),
  };
};

module.exports = mongoose.model("Registry", RegistrySchema);
