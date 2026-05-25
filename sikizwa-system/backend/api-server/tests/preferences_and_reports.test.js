const test = require('node:test');
const assert = require('node:assert/strict');

const {
  normalizeUserPreferences,
  getNotificationPreferences,
  shouldSendNotification,
} = require('../src/utils/settings');
const { serializeReport } = require('../src/utils/reportSerializer');

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
    type: 'depression',
    description: 'Feeling overwhelmed and needing support.',
    media: [],
    location: null,
    riskLevel: 'high',
    status: 'open',
    createdAt,
  });

  assert.deepStrictEqual(serialized, {
    id: '6847b6b6c09fa12f0d83a1dd',
    type: 'depression',
    title: 'Depression',
    description: 'Feeling overwhelmed and needing support.',
    emotional_summary: 'Feeling overwhelmed and needing support.',
    mood_status: 'Elevated',
    risk_level: 'high',
    riskLevel: 'high',
    status: 'open',
    created_at: createdAt.toISOString(),
    createdAt: createdAt.toISOString(),
    media: [],
    location: null,
  });
});
