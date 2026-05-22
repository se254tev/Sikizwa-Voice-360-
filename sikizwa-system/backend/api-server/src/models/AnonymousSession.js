const mongoose = require('mongoose');
const { Schema } = mongoose;

const anonymousSessionSchema = new Schema({
  anonId: { type: String, required: true, unique: true, index: true },
  createdAt: { type: Date, default: Date.now },
  lastSeenAt: { type: Date, default: Date.now },
  metadata: { type: Schema.Types.Mixed }
}, { timestamps: true });

module.exports = mongoose.model('AnonymousSession', anonymousSessionSchema);
