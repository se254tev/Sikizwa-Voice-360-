const SafeSpace = require('../models/SafeSpace');
const AuditLog = require('../models/AuditLog');

async function listSafeSpaces(req, res, next) {
  try {
    const filters = {};
    if (req.query.topic) filters.topic = req.query.topic;
    if (req.query.language) filters.language = req.query.language;
    const spaces = await SafeSpace.find(filters).sort({ membersCount: -1 }).limit(100);
    res.json(spaces);
  } catch (err) {
    next(err);
  }
}

async function createSafeSpace(req, res, next) {
  try {
    const space = await SafeSpace.create(req.body);
    await AuditLog.create({
      actor: req.user._id,
      actorAnonId: req.user.anonymousId,
      action: 'create_safe_space',
      resource: 'SafeSpace',
      resourceId: space._id,
      ip: req.ip
    });
    res.status(201).json(space);
  } catch (err) {
    next(err);
  }
}

module.exports = { listSafeSpaces, createSafeSpace };