const mongoose = require('mongoose');
const { Schema } = mongoose;

const emergencySchema = new Schema({
  reporterAnonId: { type: String, index: true },
  reporterUser: { type: Schema.Types.ObjectId, ref: 'User', index: true },
  location: { type: { type: String, enum: ['Point'], default: 'Point' }, coordinates: { type: [Number], index: '2dsphere' } },
  status: { type: String, enum: ['pending','dispatched','resolved','cancelled'], default: 'pending', index: true },
  responders: [{ type: Schema.Types.ObjectId, ref: 'User' }],
  severity: { type: String, enum: ['low','medium','high','emergency'], default: 'low', index: true },
  notes: String,
  createdAt: { type: Date, default: Date.now, index: true }
}, { timestamps: true });

module.exports = mongoose.model('Emergency', emergencySchema);
