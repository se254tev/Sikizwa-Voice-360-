const LearningResource = require('../models/LearningResource');
const AuditLog = require('../models/AuditLog');

async function listResources(req, res, next) {
  try {
    const filters = {};
    if (req.query.language) filters.languages = req.query.language;
    if (req.query.category) filters.categories = req.query.category;
    const resources = await LearningResource.find(filters).sort({ publishedAt: -1 }).limit(100);
    res.json(resources);
  } catch (err) {
    next(err);
  }
}

async function createResource(req, res, next) {
  try {
    const resource = await LearningResource.create(req.body);
    await AuditLog.create({
      actor: req.user._id,
      actorAnonId: req.user.anonymousId,
      action: 'create_learning_resource',
      resource: 'LearningResource',
      resourceId: resource._id,
      ip: req.ip
    });
    res.status(201).json(resource);
  } catch (err) {
    next(err);
  }
}

module.exports = { listResources, createResource };