const mongoose = require('mongoose');

const productSchema = new mongoose.Schema({
  skuId: { type: String, required: true, unique: true },
  name: { type: String, required: true },
  description: String,
  price: { type: Number, required: true },
  images: [String],
  category: String,
  
  // Product Details
  specs: [String], // Array of specifications/features
  stars: { type: Number, default: 0, min: 0, max: 5 }, // Overall rating
  reviews: [{
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    rating: { type: Number, required: true, min: 1, max: 5 },
    comment: String,
    createdAt: { type: Date, default: Date.now }
  }],
  
  // AR Specific Fields
  arModelUrl: String,
  arScale: { type: Number, default: 1.0 },
  arPlacementType: { type: String, default: 'tabletop' } // 'floor' or 'tabletop'
});

module.exports = mongoose.model('Product', productSchema);
