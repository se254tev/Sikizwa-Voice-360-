const mongoose = require('mongoose');
const { Schema } = mongoose;

const reportSchema = new Schema({
  reporterAnonId: { type: String, index: true },
  reporterUser: { type: Schema.Types.ObjectId, ref: 'User' },
  type: {
    type: String,
    enum: ['gbv','depression','suicide','bullying','corruption','insecurity','drug','harassment','support','general'],
    required: true,
    index: true,
    default: 'support',
  },
  reportType: { type: String, trim: true, default: 'problem', index: true },
  incidentType: { type: String, trim: true },
  title: { type: String, trim: true },
  description: { type: String, trim: true },
  emotional_summary: { type: String, trim: true },
  mood_status: { type: String, trim: true },
  media: [{ url: String, type: String }],
  locationText: { type: String, trim: true, default: '' },
  location: {
    type: { type: String, enum: ['Point'], required: false },
    coordinates: { type: [Number], required: false }
  },
  anonymousSubmission: { type: Boolean, default: false, index: true },
  priority: { type: String, enum: ['low','medium','high'], default: 'medium', index: true },
  timestamp: { type: Date, default: Date.now },
  emotionAnalysis: { type: Schema.Types.ObjectId, ref: 'EmotionalAnalysis' },
  riskLevel: { type: String, enum: ['low','medium','high','emergency'], default: 'low', index: true },
  status: {
    type: String,
    enum: ['pending','open','in-progress','resolved','closed','escalated'],
    default: 'pending',
    index: true,
  },
  isDeleted: { type: Boolean, default: false, index: true },
  deletedAt: { type: Date },
  deletedBy: { type: Schema.Types.ObjectId, ref: 'User' },
  createdAt: { type: Date, default: Date.now }
});

reportSchema.index({ locationText: 1 });
reportSchema.index(
  { location: '2dsphere' },
  { partialFilterExpression: { 'location.type': 'Point' } }
);
reportSchema.index({ reporterUser: 1 });
reportSchema.index({ createdAt: -1 });
module.exports = mongoose.model('Report', reportSchema);
