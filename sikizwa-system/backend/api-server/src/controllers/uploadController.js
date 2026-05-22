const { uploadBuffer } = require('../services/cloudinaryService');
const AuditLog = require('../models/AuditLog');

async function uploadFile(req, res, next) {
  try {
    if (!req.file) return res.status(400).json({ error: 'file required' });
    const result = await uploadBuffer(req.file.buffer, {
      resource_type: 'auto',
      folder: 'sikizwa/uploads'
    });

    await AuditLog.create({
      actor: req.user._id,
      actorAnonId: req.user.anonymousId,
      action: 'upload_media',
      resource: 'Upload',
      ip: req.ip,
      meta: { url: result.secure_url, type: result.resource_type }
    });
    res.status(201).json({ url: result.secure_url, publicId: result.public_id });
  } catch (err) {
    next(err);
  }
}

module.exports = { uploadFile };