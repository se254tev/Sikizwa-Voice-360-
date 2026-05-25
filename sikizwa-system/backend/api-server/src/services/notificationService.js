const Notification = require('../models/Notification');
const User = require('../models/User');
const { io } = require('../utils/socketRegistry');
const { shouldSendNotification } = require('../utils/settings');

async function notifyEmergency(emergency) {
  await Notification.create({
    toUser: null,
    type: 'emergency_alert',
    title: 'SOS Alert Triggered',
    body: 'A user has triggered an emergency alert.',
    data: { emergencyId: emergency._id, severity: emergency.severity }
  });
  if (io) {
    io.to('emergency-monitoring').emit('emergency.created', { id: emergency._id, severity: emergency.severity });
  }
}

async function sendNotification(userId, payload) {
  const user = await User.findById(userId).select('preferences');
  if (!user || !shouldSendNotification(user, payload.channel || 'push')) {
    return null;
  }

  const notification = await Notification.create({
    toUser: userId,
    type: payload.type,
    title: payload.title,
    body: payload.body,
    data: payload.data
  });
  if (io) {
    io.to(userId.toString()).emit('notification', notification);
  }
  return notification;
}

module.exports = { notifyEmergency, sendNotification };