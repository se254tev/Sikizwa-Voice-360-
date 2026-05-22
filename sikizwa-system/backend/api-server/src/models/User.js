const mongoose = require('mongoose');
const { Schema } = mongoose;

const userSchema = new Schema({
  role: { type: String, enum: ['user','counsellor','admin','responder'], default: 'user', index: true },
  anonymousId: { type: String, index: true },
  username: { type: String },
  passwordHash: { type: String },
  languages: [{ type: String }],
  region: { type: String },
  phone: { type: String },
  metadata: { type: Schema.Types.Mixed },
  createdAt: { type: Date, default: Date.now }
});

userSchema.index({ anonymousId: 1 }, { unique: true, sparse: true });

module.exports = mongoose.model('User', userSchema);
