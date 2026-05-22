const mongoose = require('mongoose');
const { Schema } = mongoose;

const counsellorSchema = new Schema({
  user: { type: Schema.Types.ObjectId, ref: 'User', required: true, unique: true },
  languages: [{ type: String, index: true }],
  regions: [{ type: String, index: true }],
  specialties: [{ type: String, index: true }],
  rating: { type: Number, default: 0 },
  active: { type: Boolean, default: true },
  availability: { type: String, enum: ['online','offline','busy'], default: 'offline' },
  createdAt: { type: Date, default: Date.now }
}, { timestamps: true });

module.exports = mongoose.model('Counsellor', counsellorSchema);
