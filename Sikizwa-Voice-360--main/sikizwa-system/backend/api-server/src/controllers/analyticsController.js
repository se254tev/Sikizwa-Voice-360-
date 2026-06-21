const Report = require('../models/Report');
const Emergency = require('../models/Emergency');
const AuditLog = require('../models/AuditLog');

async function overview(req, res, next) {
  try {
    const [reportCount, emergencyCount, recentAudits] = await Promise.all([
      Report.countDocuments(),
      Emergency.countDocuments(),
      AuditLog.find().sort({ createdAt: -1 }).limit(20)
    ]);
    res.json({ reportCount, emergencyCount, recentAudits });
  } catch (err) {
    next(err);
  }
}

async function reportTrends(req, res, next) {
  try {
    const trends = await Report.aggregate([
      { $match: {} },
      { $group: { _id: '$type', count: { $sum: 1 } } },
      { $sort: { count: -1 } }
    ]);
    res.json({ trends });
  } catch (err) {
    next(err);
  }
}

module.exports = { overview, reportTrends };