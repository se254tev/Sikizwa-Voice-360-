const mongoose = require('mongoose');
const { Schema } = mongoose;

const safeSpaceSchema = new Schema({
  name: { type: String, required: true, index: true },
  description: String,
  language: String,
  topic: String,
  anonymous: { type: Boolean, default: true },
  membersCount: { type: Number, default: 0 }
}, { timestamps: true });

module.exports = mongoose.model('SafeSpace', safeSpaceSchema);
