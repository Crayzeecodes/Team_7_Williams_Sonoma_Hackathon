const mongoose = require('mongoose');

const registrySchema = new mongoose.Schema({
  adminId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  name: { type: String, required: true },
  joinCode: { type: String, required: true, unique: true },
  registryType: { type: String, enum: ['event', 'gifting'], required: true },
  shippingAddress: {
    street: String,
    city: String,
    state: String,
    zipCode: String
  },
  
  // Specific to "Events"
  eventDetails: {
    plannerAnswers: mongoose.Schema.Types.Mixed, // Stores answers from AI planner
    targetBudget: Number,
    paymentSplitType: { type: String, enum: ['dutch', 'evenly'] }
  },

  // Specific to "Gifting"
  giftingDetails: {
    category: String,
    pooledBudget: { type: Number, default: 0 }
  },

  // Shared Fields
  members: [{
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    contributedBudget: { type: Number, default: 0 }
  }],
  
  cartItems: [{
    productId: { type: mongoose.Schema.Types.ObjectId, ref: 'Product' },
    addedByUserId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    source: { type: String, enum: ['manual', 'ai'], default: 'manual' },
    status: { type: String, enum: ['in_cart', 'purchased'], default: 'in_cart' }
  }],

  polls: [{
    question: String,
    options: [{
      productId: { type: mongoose.Schema.Types.ObjectId, ref: 'Product' },
      votes: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }]
    }],
    status: { type: String, enum: ['active', 'closed'], default: 'active' }
  }],
  
  createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Registry', registrySchema);
