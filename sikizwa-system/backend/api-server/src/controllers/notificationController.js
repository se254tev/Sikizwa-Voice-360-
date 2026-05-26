const Notification = require('../models/Notification');
const AuditLog = require('../models/AuditLog');
const { ApiError } = require('../utils/apiError');
const { NOT_FOUND_ERRORS } = require('../utils/errorMessages');

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
    if (!notification) {
      throw new ApiError({
        statusCode: 404,
        message: NOT_FOUND_ERRORS.resourceNotFound.message,
        errorCode: NOT_FOUND_ERRORS.resourceNotFound.errorCode,
      });
    }
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