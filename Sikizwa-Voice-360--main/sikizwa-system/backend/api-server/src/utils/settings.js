const DEFAULT_PREFERENCES = {
  notifications: {
    push_enabled: true,
    email_enabled: true,
    sms_enabled: false,
  },
  privacy: {
    analytics_tracking: true,
    crash_reporting_consent: false,
    profile_visibility: 'private',
  },
};

function normalizePrivacy(privacy = {}) {
  const normalized = {
    ...DEFAULT_PREFERENCES.privacy,
    ...(privacy && typeof privacy === 'object' ? privacy : {}),
  };

  if (!['private', 'public', 'anonymous'].includes(normalized.profile_visibility)) {
    normalized.profile_visibility = DEFAULT_PREFERENCES.privacy.profile_visibility;
  }

  return normalized;
}

function normalizeNotifications(notifications = {}) {
  return {
    ...DEFAULT_PREFERENCES.notifications,
    ...(notifications && typeof notifications === 'object' ? notifications : {}),
  };
}

function normalizeUserPreferences(input = {}) {
  const preferences = input && typeof input === 'object' ? input : {};

  return {
    notifications: normalizeNotifications(preferences.notifications),
    privacy: normalizePrivacy(preferences.privacy),
  };
}

function getUserPreferences(user) {
  return normalizeUserPreferences(user?.preferences || {});
}

function getNotificationPreferences(user) {
  return getUserPreferences(user).notifications;
}

function getPrivacySettings(user) {
  return getUserPreferences(user).privacy;
}

function normalizeChannel(channel) {
  if (channel === 'email') return 'email';
  if (channel === 'sms') return 'sms';
  return 'push';
}

function shouldSendNotification(user, channel) {
  const normalizedChannel = normalizeChannel(channel);
  const preferences = getNotificationPreferences(user);

  if (normalizedChannel === 'email') {
    return preferences.email_enabled === true;
  }

  if (normalizedChannel === 'sms') {
    return preferences.sms_enabled === true;
  }

  return preferences.push_enabled === true;
}

module.exports = {
  DEFAULT_PREFERENCES,
  normalizeUserPreferences,
  getUserPreferences,
  getNotificationPreferences,
  getPrivacySettings,
  shouldSendNotification,
};
