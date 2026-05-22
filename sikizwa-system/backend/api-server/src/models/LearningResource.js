const mongoose = require('mongoose');
const { Schema } = mongoose;

const learningResourceSchema = new Schema({
  title: { type: String, required: true, index: true },
  summary: String,
  contentUrl: String,
  media: [{ url: String, type: String }],
  categories: [{ type: String, index: true }],
  languages: [{ type: String, index: true }],
  publishedAt: Date
}, { timestamps: true });

module.exports = mongoose.model('LearningResource', learningResourceSchema);
