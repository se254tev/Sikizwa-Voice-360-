const mongoose = require('mongoose');
const { Schema } = mongoose;

const emotionalAnalysisSchema = new Schema({
  report: { type: Schema.Types.ObjectId, ref: 'Report' },
  transcript: { type: String },
  emotions: { type: Schema.Types.Mixed },
  riskScore: { type: Number, default: 0, index: true },
  tags: [{ type: String }],
  modelVersion: String
}, { timestamps: true });

module.exports = mongoose.model('EmotionalAnalysis', emotionalAnalysisSchema);
