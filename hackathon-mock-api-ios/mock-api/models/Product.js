const mongoose = require('mongoose');

const productSchema = new mongoose.Schema({
  skuId: { type: String, required: true, unique: true },
  name: { type: String, required: true },
  description: String,
  price: { type: Number, required: true },
  images: [String],
  category: String,
  arModelUrl: String,
  arScale: { type: Number, default: 1.0 },
  arPlacementType: { type: String, default: 'tabletop' } // 'floor' or 'tabletop'
});

module.exports = mongoose.model('Product', productSchema);
