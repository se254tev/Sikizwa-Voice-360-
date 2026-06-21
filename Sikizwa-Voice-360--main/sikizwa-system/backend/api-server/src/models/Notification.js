const mongoose = require('mongoose');
const { Schema } = mongoose;

const notificationSchema = new Schema({
  toUser: { type: Schema.Types.ObjectId, ref: 'User', index: true },
  type: { type: String },
  title: String,
  body: String,
  data: Schema.Types.Mixed,
  read: { type: Boolean, default: false, index: true }
}, { timestamps: true });

module.exports = mongoose.model('Notification', notificationSchema);
