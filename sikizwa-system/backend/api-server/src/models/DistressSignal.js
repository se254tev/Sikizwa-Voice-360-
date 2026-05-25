const mongoose = require('mongoose');
const { Schema } = mongoose;

const distressSignalSchema = new Schema(
  {
    user: { type: Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    lat: { type: Number, required: true },
    lng: { type: Number, required: true },
    timestamp: { type: Date, required: true, index: true },
    message: { type: String, maxlength: 500 },
    status: { type: String, enum: ['active'], default: 'active', index: true },
    severity: { type: String, enum: ['critical'], default: 'critical', index: true },
    isLockedModeActive: { type: Boolean, default: true },
    source: { type: String, default: 'APP', index: true },
    pendantId: { type: String, trim: true, index: true },
    batteryLevel: { type: Number, min: 0, max: 100 },
  },
  { timestamps: true }
);

distressSignalSchema.index({ user: 1, pendantId: 1, source: 1, status: 1, createdAt: -1 });

module.exports = mongoose.model('DistressSignal', distressSignalSchema);
