const mongoose = require('mongoose');
const { Schema } = mongoose;

const reportSchema = new Schema({
  reporterAnonId: { type: String, index: true },
  reporterUser: { type: Schema.Types.ObjectId, ref: 'User' },
  type: { type: String, enum: ['gbv','depression','suicide','bullying','corruption','insecurity','drug','harassment'], required: true, index: true },
  title: { type: String },
  description: { type: String },
  emotional_summary: { type: String },
  mood_status: { type: String },
  media: [{ url: String, type: String }],
  location: { type: { type: String, enum: ['Point'], default: 'Point' }, coordinates: [Number] },
  emotionAnalysis: { type: Schema.Types.ObjectId, ref: 'EmotionalAnalysis' },
  riskLevel: { type: String, enum: ['low','medium','high','emergency'], default: 'low', index: true },
  status: { type: String, enum: ['open','in-progress','closed'], default: 'open' },
  createdAt: { type: Date, default: Date.now }
});

reportSchema.index({ location: '2dsphere' });
reportSchema.index({ reporterUser: 1 });
reportSchema.index({ createdAt: -1 });
reportSchema.index({ status: 1 });
module.exports = mongoose.model('Report', reportSchema);
