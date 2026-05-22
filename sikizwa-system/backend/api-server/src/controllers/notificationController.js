const Notification = require('../models/Notification');
const AuditLog = require('../models/AuditLog');

async function listNotifications(req, res, next) {
  try {
    const notifications = await Notification.find({ toUser: req.user._id }).sort({ createdAt: -1 }).limit(50);
    res.json(notifications);
  } catch (err) {
    next(err);
  }
}

async function markRead(req, res, next) {
  try {
    const notification = await Notification.findOneAndUpdate(
      { _id: req.params.id, toUser: req.user._id },
      { read: true },
      { new: true }
    );
    if (!notification) return res.status(404).json({ error: 'notification not found' });
    await AuditLog.create({
      actor: req.user._id,
      actorAnonId: req.user.anonymousId,
      action: 'mark_notification_read',
      resource: 'Notification',
      resourceId: notification._id,
      ip: req.ip
    });
    res.json(notification);
  } catch (err) {
    next(err);
  }
}

module.exports = { listNotifications, markRead };