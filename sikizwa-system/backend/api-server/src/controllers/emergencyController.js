const Emergency = require('../models/Emergency');
const AuditLog = require('../models/AuditLog');
const { scoreEmergency } = require('../services/riskService');
const { notifyEmergency } = require('../services/notificationService');

async function createEmergency(req, res, next) {
  try {
    const { location, notes, trustedContacts } = req.body;
    const severity = scoreEmergency(req.body);
    const emergency = await Emergency.create({
      reporterUser: req.user._id,
      reporterAnonId: req.user.anonymousId,
      location,
      notes,
      severity,
      status: 'pending',
      meta: { trustedContacts }
    });

    await notifyEmergency(emergency);
    await AuditLog.create({
      actor: req.user._id,
      actorAnonId: req.user.anonymousId,
      action: 'create_emergency',
      resource: 'Emergency',
      resourceId: emergency._id,
      ip: req.ip,
      meta: { severity }
    });

    res.status(201).json(emergency);
  } catch (err) {
    next(err);
  }
}

async function listEmergencies(req, res, next) {
  try {
    const query = {};
    if (req.query.status) query.status = req.query.status;
    const emergencies = await Emergency.find(query)
      .populate('reporterUser', 'username role')
      .sort({ createdAt: -1 })
      .limit(100);
    res.json(emergencies);
  } catch (err) {
    next(err);
  }
}

async function resolveEmergency(req, res, next) {
  try {
    const emergency = await Emergency.findById(req.params.id);
    if (!emergency) return res.status(404).json({ error: 'Emergency not found' });
    emergency.status = 'resolved';
    await emergency.save();
    await AuditLog.create({
      actor: req.user._id,
      actorAnonId: req.user.anonymousId,
      action: 'resolve_emergency',
      resource: 'Emergency',
      resourceId: emergency._id,
      ip: req.ip
    });
    res.json(emergency);
  } catch (err) {
    next(err);
  }
}

module.exports = { createEmergency, listEmergencies, resolveEmergency };