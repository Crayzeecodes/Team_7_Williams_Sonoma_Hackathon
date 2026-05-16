/**
 * ============================================================
 *  REGISTRY TAB — MONGODB / MONGOOSE COLLECTIONS
 *  AI: xAI Grok (grok-3-mini) for product recommendations
 * ============================================================
 */

const mongoose = require('mongoose');
const { Schema, model, Types } = mongoose;


/* ─────────────────────────────────────────────
   SHARED SUB-SCHEMAS
───────────────────────────────────────────── */

const AddressSchema = new Schema(
  {
    street:  { type: String, trim: true },
    city:    { type: String, trim: true },
    state:   { type: String, trim: true },
    zipCode: { type: String, trim: true },
    country: { type: String, trim: true, default: 'US' },
  },
  { _id: false }
);

const CurrencySchema = new Schema(
  {
    code:   { type: String, default: 'USD' },   // ISO 4217
    symbol: { type: String, default: '$' },
  },
  { _id: false }
);


/* ─────────────────────────────────────────────
   1. REGISTRIES
───────────────────────────────────────────── */

// AI suggestion entry (cached Grok output)
const AiSuggestionSchema = new Schema(
  {
    productId:   { type: Types.ObjectId, ref: 'Product', required: true },
    score:       { type: Number },          // ranking score 0-1 from Grok
    reasoning:   { type: String },          // one-line blurb, max 12 words
    generatedAt: { type: Date, default: Date.now },
  },
  { _id: false }
);

// Shared cart item
const RegistryCartItemSchema = new Schema(
  {
    productId:     { type: Types.ObjectId, ref: 'Product', required: true },
    addedByUserId: { type: Types.ObjectId, ref: 'User',    required: true },
    quantity:      { type: Number, default: 1, min: 1 },
    price:         { type: Number, required: true },   // price snapshot at time of add
    name:          { type: String },                   // product name snapshot
    imageUrl:      { type: String },                   // first image snapshot
    source:        { type: String, enum: ['manual', 'ai'], default: 'manual' },
    status:        { type: String, enum: ['in_cart', 'purchased'], default: 'in_cart' },
    addedAt:       { type: Date, default: Date.now },
  },
  { _id: true }
);

// Member
const RegistryMemberSchema = new Schema(
  {
    userId:            { type: Types.ObjectId, ref: 'User', required: true },
    role:              { type: String, enum: ['admin', 'collaborator'], default: 'collaborator' },
    contributedBudget: { type: Number, default: 0 },   // dutch gifting only
    joinedAt:          { type: Date, default: Date.now },
  },
  { _id: false }
);

// Poll
const PollSchema = new Schema(
  {
    question: { type: String, required: true },
    options: [{
      productId: { type: Types.ObjectId, ref: 'Product' },
      votes:     [{ type: Types.ObjectId, ref: 'User' }],
      _id: false,
    }],
    status:    { type: String, enum: ['active', 'closed'], default: 'active' },
    createdAt: { type: Date, default: Date.now },
  },
  { _id: true }
);

// Budget snapshot (denormalized — recalculated server-side on every cart mutation)
const BudgetSnapshotSchema = new Schema(
  {
    totalBudget:     { type: Number, default: 0 },
    spentAmount:     { type: Number, default: 0 },
    remainingAmount: { type: Number, default: 0 },
    lastUpdated:     { type: Date, default: Date.now },
  },
  { _id: false }
);

// Root registry schema
const RegistrySchema = new Schema(
  {
    adminId:      { type: Types.ObjectId, ref: 'User', required: true },
    name:         { type: String, required: true, trim: true },
    joinCode:     { type: String, required: true, unique: true, uppercase: true }, // 6-char e.g. 'A3F9KZ'
    registryType: { type: String, enum: ['event', 'gifting'], required: true },

    // Common step 1 fields
    creatorName: { type: String, required: true, trim: true },
    eventType: {
      type: String,
      enum: ['birthday','anniversary','wedding','baby_shower','graduation','housewarming','farewell','festival','other'],
      required: true,
    },
    eventDate: { type: Date, required: true },
    currency:  CurrencySchema,

    // Event-specific (registryType === 'event')
    eventDetails: {
      aiPlannerAnswers: { type: Schema.Types.Mixed },   // { q1: '...', q2: '...', ... }
      targetBudget:     { type: Number },
      paymentSplitType: { type: String, enum: ['split', 'dutch'] },
    },

    // Gifting-specific (registryType === 'gifting')
    giftingDetails: {
      collaboratorCount: { type: Number },
      aiPlannerAnswers:  { type: Schema.Types.Mixed },
      splitType:         { type: String, enum: ['split', 'dutch'] },
      creatorBudget:     { type: Number },               // used when split
      pooledBudget:      { type: Number, default: 0 },  // Σ contributedBudgets when dutch
      budgetStatus:      { type: String, enum: ['pending', 'finalized'], default: 'pending' },
    },

    members:         [RegistryMemberSchema],
    cartItems:       [RegistryCartItemSchema],
    aiSuggestions:   [AiSuggestionSchema],
    polls:           [PollSchema],
    budgetSnapshot:  BudgetSnapshotSchema,
    shippingAddress: AddressSchema,

    createdAt: { type: Date, default: Date.now },
  },
  { timestamps: true }
);

RegistrySchema.index({ joinCode: 1 });
RegistrySchema.index({ adminId: 1 });
RegistrySchema.index({ 'members.userId': 1 });
RegistrySchema.index({ eventDate: 1 });
RegistrySchema.index({ registryType: 1, eventDate: 1 });

// Recalculate piggy bank — call before save + socket emit
RegistrySchema.methods.recalculateBudget = function () {
  const spent = this.cartItems
    .filter(i => i.status === 'in_cart')
    .reduce((sum, i) => sum + i.price * i.quantity, 0);

  let total = 0;
  if (this.registryType === 'event') {
    total = this.eventDetails?.targetBudget ?? 0;
  } else {
    total = this.giftingDetails?.splitType === 'dutch'
      ? this.giftingDetails?.pooledBudget ?? 0
      : this.giftingDetails?.creatorBudget ?? 0;
  }

  this.budgetSnapshot = {
    totalBudget:     total,
    spentAmount:     spent,
    remainingAmount: Math.max(0, total - spent),
    lastUpdated:     new Date(),
  };
};

// Accumulate dutch contributions as collaborators join
RegistrySchema.methods.addContributedBudget = function (userId, amount) {
  const member = this.members.find(m => m.userId.equals(userId));
  if (member) {
    member.contributedBudget = amount;
    this.giftingDetails.pooledBudget = this.members.reduce(
      (sum, m) => sum + (m.contributedBudget ?? 0), 0
    );
  }
};

const Registry = model('Registry', RegistrySchema);
module.exports = Registry;
