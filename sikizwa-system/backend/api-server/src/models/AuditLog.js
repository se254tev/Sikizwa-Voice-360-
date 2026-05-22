const mongoose = require('mongoose');
const { Schema } = mongoose;

const auditLogSchema = new Schema({
  actor: { type: Schema.Types.ObjectId, ref: 'User' },
  actorAnonId: String,
  action: { type: String, required: true, index: true },
  resource: { type: String },
  resourceId: { type: Schema.Types.ObjectId },
  ip: String,
  meta: Schema.Types.Mixed
}, { timestamps: true });

auditLogSchema.index({ actor: 1, action: 1, createdAt: -1 });

module.exports = mongoose.model('AuditLog', auditLogSchema);
