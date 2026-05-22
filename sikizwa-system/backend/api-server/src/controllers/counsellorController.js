const Counsellor = require('../models/Counsellor');
const User = require('../models/User');
const AuditLog = require('../models/AuditLog');

async function listCounsellors(req, res, next) {
  try {
    const counsellors = await Counsellor.find({ active: true }).populate('user', 'username role');
    res.json(counsellors);
  } catch (err) {
    next(err);
  }
}

async function matchCounsellor(req, res, next) {
  try {
    const { language, issueType, region, ageGroup } = req.body;
    const candidates = await Counsellor.find({
      active: true,
      languages: language,
      regions: region,
      specialties: issueType
    }).limit(20);

    const bestMatch = candidates.sort((a, b) => b.rating - a.rating)[0] || null;
    await AuditLog.create({
      actor: req.user._id,
      actorAnonId: req.user.anonymousId,
      action: 'match_counsellor',
      resource: 'Counsellor',
      resourceId: bestMatch?._id,
      ip: req.ip,
      meta: { language, issueType, region, ageGroup }
    });

    res.json({ match: bestMatch, candidates: candidates.length });
  } catch (err) {
    next(err);
  }
}

module.exports = { listCounsellors, matchCounsellor };