const mongoose = require('mongoose');
const { Schema } = mongoose;

const emergencyContactSchema = new Schema(
  {
    name: { type: String, required: true, trim: true },
    phone: { type: String, required: true, trim: true },
    relationship: { type: String, required: true, trim: true },
    type: { type: String, enum: ['personal', 'professional', 'guardian'], required: true, default: 'personal' },
  },
  { _id: false }
);

const medicalProfileSchema = new Schema(
  {
    bloodGroup: { type: String, trim: true },
    allergies: { type: String, trim: true },
    medicalConditions: { type: String, trim: true },
  },
  { _id: false }
);

const userSchema = new Schema(
  {
    name: { type: String, trim: true },
    fullName: { type: String, trim: true },
    role: { type: String, enum: ['user', 'counsellor', 'admin', 'responder', 'other'], default: 'other', index: true },
    anonymousId: { type: String, index: true },
    username: { type: String, trim: true },
    passwordHash: { type: String },
    languages: [{ type: String }],
    region: { type: String, trim: true },
    phone: { type: String, trim: true },
    email: { type: String, trim: true },
    emergencyContacts: [emergencyContactSchema],
    medicalProfile: medicalProfileSchema,
    location: { type: String, trim: true },
    metadata: { type: Schema.Types.Mixed },
  },
  { timestamps: true }
);

userSchema.index({ anonymousId: 1 }, { unique: true, sparse: true });
userSchema.index({ phone: 1 }, { unique: true, sparse: true });
userSchema.index({ email: 1 }, { unique: true, sparse: true });

module.exports = mongoose.model('User', userSchema);
