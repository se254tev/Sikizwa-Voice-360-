const test = require('node:test');
const assert = require('node:assert/strict');

const {
  normalizeUserPreferences,
  getNotificationPreferences,
  shouldSendNotification,
} = require('../src/utils/settings');
const { serializeReport } = require('../src/utils/reportSerializer');
const { createReport } = require('../src/controllers/reportController');
const Report = require('../src/models/Report');
const EmotionalAnalysis = require('../src/models/EmotionalAnalysis');
const AuditLog = require('../src/models/AuditLog');
const User = require('../src/models/User');
const notificationService = require('../src/services/notificationService');

test('normalizeUserPreferences merges defaults with overrides', () => {
  const result = normalizeUserPreferences({
    notifications: { push_enabled: false, sms_enabled: true },
    privacy: { profile_visibility: 'public' },
  });

  assert.deepStrictEqual(result.notifications, {
    push_enabled: false,
    email_enabled: true,
    sms_enabled: true,
  });
  assert.deepStrictEqual(result.privacy, {
    analytics_tracking: true,
    crash_reporting_consent: false,
    profile_visibility: 'public',
  });
});

test('getNotificationPreferences exposes channel flags', () => {
  const preferences = getNotificationPreferences({
    preferences: {
      notifications: { push_enabled: false, email_enabled: true, sms_enabled: false },
    },
  });

  assert.deepStrictEqual(preferences, {
    push_enabled: false,
    email_enabled: true,
    sms_enabled: false,
  });
});

test('shouldSendNotification denies disabled channels', () => {
  assert.equal(
    shouldSendNotification(
      { preferences: { notifications: { push_enabled: false, email_enabled: true, sms_enabled: false } } },
      'push'
    ),
    false
  );

  assert.equal(
    shouldSendNotification(
      { preferences: { notifications: { push_enabled: false, email_enabled: true, sms_enabled: false } } },
      'email'
    ),
    true
  );
});

test('serializeReport returns normalized reporting fields', () => {
  const createdAt = new Date('2026-05-24T12:00:00.000Z');

  const serialized = serializeReport({
    _id: '6847b6b6c09fa12f0d83a1dd',
    type: 'support',
    reportType: 'problem',
    incidentType: 'Safety concern',
    anonymousSubmission: true,
    priority: 'high',
    description: 'Feeling overwhelmed and needing support.',
    media: [],
    location: 'Near the community clinic',
    riskLevel: 'high',
    status: 'pending',
    createdAt,
    timestamp: createdAt,
  });

  assert.deepStrictEqual(serialized, {
    id: '6847b6b6c09fa12f0d83a1dd',
    type: 'support',
    reportType: 'problem',
    incidentType: 'Safety concern',
    anonymousSubmission: true,
    priority: 'high',
    title: 'Safety concern',
    description: 'Feeling overwhelmed and needing support.',
    emotional_summary: 'Feeling overwhelmed and needing support.',
    mood_status: 'Elevated',
    risk_level: 'high',
    riskLevel: 'high',
    status: 'pending',
    created_at: createdAt.toISOString(),
    createdAt: createdAt.toISOString(),
    timestamp: createdAt.toISOString(),
    media: [],
    location: 'Near the community clinic',
  });
});

test('createReport responds even when auxiliary writes are slow', async () => {
  const originalCreate = Report.create;
  const originalEmotionalCreate = EmotionalAnalysis.create;
  const originalAuditCreate = AuditLog.create;
  const originalUserFind = User.find;
  const originalSendNotification = notificationService.sendNotification;

  const reportDoc = {
    _id: '6847b6b6c09fa12f0d83a1dd',
    type: 'support',
    reportType: 'problem',
    incidentType: 'Support update',
    anonymousSubmission: true,
    priority: 'medium',
    title: 'Support update',
    description: 'Need help with staying safe.',
    emotional_summary: 'Need help with staying safe.',
    mood_status: 'Elevated',
    riskLevel: 'medium',
    status: 'pending',
    createdAt: new Date('2026-05-24T12:00:00.000Z'),
    timestamp: new Date('2026-05-24T12:00:00.000Z'),
    location: 'Near the clinic',
  };

  let response;
  const res = {
    statusCode: null,
    payload: null,
    status(code) {
      this.statusCode = code;
      return this;
    },
    json(payload) {
      this.payload = payload;
      return this;
    },
  };

  Report.create = async () => reportDoc;
  EmotionalAnalysis.create = () => new Promise(() => {});
  AuditLog.create = async () => ({ ok: true });
  User.find = () => ({
    select: async () => [],
  });
  notificationService.sendNotification = async () => null;

  try {
    const controllerResponse = createReport(
      {
        body: {
          reportType: 'problem',
          incidentType: 'Support update',
          description: 'Need help with staying safe.',
          location: 'Near the clinic',
          anonymousSubmission: true,
          priority: 'medium',
        },
        user: {
          anonymousId: 'anon-123',
        },
        ip: '127.0.0.1',
      },
      res,
      () => {}
    );

    response = await Promise.race([
      controllerResponse,
      new Promise((resolve) => setTimeout(() => resolve('timeout'), 20)),
    ]);
  } finally {
    Report.create = originalCreate;
    EmotionalAnalysis.create = originalEmotionalCreate;
    AuditLog.create = originalAuditCreate;
    User.find = originalUserFind;
    notificationService.sendNotification = originalSendNotification;
  }

  assert.equal(response, undefined);
  assert.equal(res.statusCode, 201);
  assert.equal(res.payload.id, reportDoc._id);
});
