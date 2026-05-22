const mongoose = require('mongoose');
const { Schema } = mongoose;

const messageSchema = new Schema({
  senderType: { type: String, enum: ['user','counsellor','system'], required: true },
  senderRef: { type: Schema.Types.ObjectId, ref: 'User' },
  text: String,
  media: [{ url: String, type: String }],
  createdAt: { type: Date, default: Date.now }
}, { _id: false });

const supportChatSchema = new Schema({
  participants: [{ type: Schema.Types.ObjectId, ref: 'User' }],
  anonSession: { type: Schema.Types.ObjectId, ref: 'AnonymousSession' },
  messages: [messageSchema],
  lastMessageAt: { type: Date, default: Date.now },
  meta: Schema.Types.Mixed
}, { timestamps: true });

supportChatSchema.index({ participants: 1, lastMessageAt: -1 });

module.exports = mongoose.model('SupportChat', supportChatSchema);
