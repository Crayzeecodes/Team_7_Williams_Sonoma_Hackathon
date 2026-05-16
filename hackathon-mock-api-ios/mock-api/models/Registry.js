const mongoose = require("mongoose");

const currencySchema = new mongoose.Schema(
  {
    code: { type: String, required: true },
    symbol: { type: String, required: true },
  },
  { _id: false }
);

const plannerAnswerSchema = new mongoose.Schema(
  {
    question: { type: String, required: true },
    answer: { type: String, required: true },
  },
  { _id: false }
);

const eventDetailsSchema = new mongoose.Schema(
  {
    aiPlannerAnswers: {
      type: [plannerAnswerSchema],
      default: [],
    },
    targetBudget: {
      type: Number,
      default: 0,
      min: 0,
    },
    paymentSplitType: {
      type: String,
      enum: ["split", "dutch"],
      default: "split",
    },
  },
  { _id: false }
);

const giftingDetailsSchema = new mongoose.Schema(
  {
    collaboratorCount: {
      type: Number,
      default: 1,
      min: 1,
      max: 20,
    },
    aiPlannerAnswers: {
      type: [plannerAnswerSchema],
      default: [],
    },
    splitType: {
      type: String,
      enum: ["split", "dutch"],
      default: "split",
    },
    creatorBudget: {
      type: Number,
      default: 0,
      min: 0,
    },
    pooledBudget: {
      type: Number,
      default: 0,
      min: 0,
    },
    budgetStatus: {
      type: String,
      enum: ["pending", "finalized"],
      default: "pending",
    },
  },
  { _id: false }
);

const memberSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    role: {
      type: String,
      enum: ["admin", "collaborator"],
      required: true,
    },
    contributedBudget: {
      type: Number,
      default: 0,
      min: 0,
    },
    joinedAt: {
      type: Date,
      default: Date.now,
    },
  },
  { _id: false }
);

const cartItemSchema = new mongoose.Schema(
  {
    productId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Product",
      required: true,
    },
    addedByUserId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    quantity: {
      type: Number,
      required: true,
      min: 1,
    },
    price: {
      type: Number,
      required: true,
      min: 0,
    },
    name: {
      type: String,
      required: true,
    },
    imageUrl: {
      type: String,
      default: "",
    },
    source: {
      type: String,
      enum: ["manual", "ai"],
      required: true,
    },
    status: {
      type: String,
      enum: ["in_cart", "purchased"],
      default: "in_cart",
    },
    addedAt: {
      type: Date,
      default: Date.now,
    },
  },
  { _id: true }
);

const aiSuggestionSchema = new mongoose.Schema(
  {
    productId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Product",
      required: true,
    },
    score: {
      type: Number,
      required: true,
      min: 0,
      max: 1,
    },
    reasoning: {
      type: String,
      required: true,
      maxlength: 120,
    },
    generatedAt: {
      type: Date,
      default: Date.now,
    },
  },
  { _id: false }
);

const pollVoteSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
  },
  { _id: false }
);

const pollOptionSchema = new mongoose.Schema(
  {
    productId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Product",
      required: true,
    },
    votes: {
      type: [pollVoteSchema],
      default: [],
    },
  },
  { _id: false }
);

const pollSchema = new mongoose.Schema(
  {
    question: {
      type: String,
      required: true,
    },
    options: {
      type: [pollOptionSchema],
      default: [],
    },
    status: {
      type: String,
      enum: ["active", "closed"],
      default: "active",
    },
    createdAt: {
      type: Date,
      default: Date.now,
    },
  },
  { _id: false }
);

const budgetSnapshotSchema = new mongoose.Schema(
  {
    totalBudget: {
      type: Number,
      default: 0,
      min: 0,
    },
    spentAmount: {
      type: Number,
      default: 0,
      min: 0,
    },
    remainingAmount: {
      type: Number,
      default: 0,
      min: 0,
    },
    lastUpdated: {
      type: Date,
      default: Date.now,
    },
  },
  { _id: false }
);

const registrySchema = new mongoose.Schema({
  adminId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "User",
    required: true,
    index: true,
  },
  name: {
    type: String,
    required: true,
    trim: true,
  },
  joinCode: {
    type: String,
    required: true,
    unique: true,
    uppercase: true,
    minlength: 6,
    maxlength: 6,
    index: true,
  },
  registryType: {
    type: String,
    enum: ["event", "gifting"],
    required: true,
  },
  creatorName: {
    type: String,
    required: true,
    trim: true,
  },
  eventType: {
    type: String,
    enum: ["birthday", "anniversary", "wedding", "baby_shower", "graduation", "housewarming", "farewell", "festival", "other"],
    required: true,
  },
  eventDate: {
    type: Date,
    required: true,
  },
  currency: {
    type: currencySchema,
    required: true,
  },
  eventDetails: {
    type: eventDetailsSchema,
    default: () => ({}),
  },
  giftingDetails: {
    type: giftingDetailsSchema,
    default: () => ({}),
  },
  members: {
    type: [memberSchema],
    default: [],
  },
  cartItems: {
    type: [cartItemSchema],
    default: [],
  },
  aiSuggestions: {
    type: [aiSuggestionSchema],
    default: [],
  },
  polls: {
    type: [pollSchema],
    default: [],
  },
  budgetSnapshot: {
    type: budgetSnapshotSchema,
    default: () => ({}),
  },
  shippingAddress: {
    type: String,
    default: "",
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
});

registrySchema.index({ joinCode: 1 });
registrySchema.index({ adminId: 1 });
registrySchema.index({ "members.userId": 1 });
registrySchema.index({ eventDate: 1 });
registrySchema.index({ registryType: 1, eventDate: 1 });

registrySchema.methods.recalculateBudget = function recalculateBudget() {
  const spent = (this.cartItems || [])
    .filter((item) => item.status === "in_cart")
    .reduce((sum, item) => sum + Number(item.price || 0) * Number(item.quantity || 0), 0);

  let total = 0;
  if (this.registryType === "event") {
    total = Number(this.eventDetails?.targetBudget || 0);
  } else if (this.giftingDetails?.splitType === "dutch") {
    total = Number(this.giftingDetails?.pooledBudget || 0);
  } else {
    total = Number(this.giftingDetails?.creatorBudget || 0);
  }

  this.budgetSnapshot = {
    totalBudget: total,
    spentAmount: spent,
    remainingAmount: Math.max(0, total - spent),
    lastUpdated: new Date(),
  };
};

registrySchema.methods.addContributedBudget = function addContributedBudget(userId, amount) {
  const member = (this.members || []).find((item) => String(item.userId) === String(userId));
  if (!member) {
    return;
  }

  member.contributedBudget = Number(amount || 0);
  this.giftingDetails.pooledBudget = (this.members || []).reduce(
    (sum, item) => sum + Number(item.contributedBudget || 0),
    0
  );
};

module.exports = mongoose.models.Registry || mongoose.model("Registry", registrySchema);
