const mongoose = require('mongoose');
const { Schema } = mongoose;

const deviceSchema = new Schema({
  userId: { type: Schema.Types.ObjectId, ref: 'User', required: true, index: true },
  deviceId: { type: String, required: true, unique: true, index: true },
  deviceType: { type: String, enum: ['phone', 'tablet', 'tv', 'watch'], required: true },
  pairedAt: { type: Date, default: Date.now },
  isPrimary: { type: Boolean, default: false },
  isActive: { type: Boolean, default: true },
}, { timestamps: true });

deviceSchema.index({ userId: 1, deviceType: 1 });

module.exports = mongoose.model('Device', deviceSchema);
