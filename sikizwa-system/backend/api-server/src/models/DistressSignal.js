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
  },
  { timestamps: true }
);

module.exports = mongoose.model('DistressSignal', distressSignalSchema);
