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

const preferencesSchema = new Schema(
  {
    notifications: {
      push_enabled: { type: Boolean, default: true },
      email_enabled: { type: Boolean, default: true },
      sms_enabled: { type: Boolean, default: false },
    },
    privacy: {
      analytics_tracking: { type: Boolean, default: true },
      crash_reporting_consent: { type: Boolean, default: false },
      profile_visibility: {
        type: String,
        enum: ['private', 'public', 'anonymous'],
        default: 'private',
      },
    },
  },
  { _id: false }
);

const userSchema = new Schema(
  {
    name: { type: String, trim: true },
    fullName: { type: String, trim: true },
    role: { type: String, enum: ['user', 'counsellor', 'admin', 'super_admin', 'responder', 'other'], default: 'other', index: true },
    permissions: [{ type: String }],
    anonymousId: { type: String },
    username: { type: String, trim: true },
    passwordHash: { type: String },
    passwordChangedAt: { type: Date, default: Date.now },
    resetOtpHash: { type: String, default: null },
    resetOtpExpiresAt: { type: Date, default: null },
    resetOtpAttempts: { type: Number, default: 0 },
    resetOtpLockedUntil: { type: Date, default: null },
    resetOtpVerifiedAt: { type: Date, default: null },
    languages: [{ type: String }],
    region: { type: String, trim: true },
    phone: { type: String, trim: true },
    phoneNumber: { type: String, trim: true },
    email: { type: String, trim: true },
    nationalId: { type: String, trim: true },
    isActive: { type: Boolean, default: true, index: true },
    suspendedAt: { type: Date, default: null },
    emergencyContacts: [emergencyContactSchema],
    medicalProfile: medicalProfileSchema,
    location: { type: String, trim: true },
    metadata: { type: Schema.Types.Mixed },
    preferences: { type: preferencesSchema, default: () => ({}) },
  },
  { timestamps: true }
);

userSchema.index({ anonymousId: 1 }, { unique: true, sparse: true });
userSchema.index({ phone: 1 }, { unique: true, sparse: true });
userSchema.index({ phoneNumber: 1 }, { unique: true });
userSchema.index({ email: 1 }, { unique: true });
userSchema.index({ nationalId: 1 }, { unique: true });
userSchema.index({ 'metadata.trustedPendants.pendantId': 1 }, { sparse: true });
userSchema.index({ role: 1 });

module.exports = mongoose.model('User', userSchema);
