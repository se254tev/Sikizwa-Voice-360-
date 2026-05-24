const jwt = require('jsonwebtoken');
const bcrypt = require('bcrypt');
const mongoose = require('mongoose');
const User = require('../models/User');
const Device = require('../models/Device');

function signToken(payload, secret, expiresIn = '15m') {
  return jwt.sign(payload, secret, { expiresIn });
}

function parsePhone(value) {
  if (typeof value !== 'string') {
    throw new Error('phone is required');
  }

  const normalized = value.trim();
  if (!/^\+?[0-9]{7,15}$/.test(normalized)) {
    throw new Error('phone must be a valid international number');
  }

  return normalized;
}

function parseDeviceType(value) {
  if (!['phone', 'tablet', 'tv', 'watch'].includes(value)) {
    throw new Error('device_type must be phone, tablet, tv, or watch');
  }
  return value;
}

function parseDeviceId(value) {
  if (typeof value !== 'string' || value.trim().length === 0) {
    throw new Error('device_id is required');
  }
  return value.trim();
}

async function authenticateUser(phone, password) {
  const user = await User.findOne({ $or: [{ phone }, { username: phone }] });
  if (!user) {
    throw new Error('invalid credentials');
  }

  const ok = await bcrypt.compare(password, user.passwordHash || '');
  if (!ok) {
    throw new Error('invalid credentials');
  }

  return user;
}

async function issuePairingCode(req, res) {
  try {
    const deviceId = parseDeviceId(req.body.device_id);
    const deviceType = parseDeviceType(req.body.device_type);

    const payload = {
      deviceId,
      deviceType,
      purpose: 'device-link',
    };

    const pairingCode = jwt.sign(payload, process.env.JWT_SECRET, { expiresIn: '10m' });

    return res.json({
      deviceId,
      deviceType,
      pairingCode,
      expiresAt: new Date(Date.now() + 10 * 60 * 1000).toISOString(),
    });
  } catch (err) {
    return res.status(400).json({ error: err.message });
  }
}

async function linkDevice(req, res) {
  try {
    const deviceId = parseDeviceId(req.body.device_id);
    const deviceType = parseDeviceType(req.body.device_type);
    const pairingCode = typeof req.body.pairing_code === 'string' ? req.body.pairing_code.trim() : '';

    if (!pairingCode) {
      return res.status(400).json({ error: 'pairing_code is required' });
    }

    let parsedPairing;
    try {
      parsedPairing = jwt.verify(pairingCode, process.env.JWT_SECRET);
    } catch (err) {
      return res.status(400).json({ error: 'invalid pairing code' });
    }

    if (parsedPairing.purpose !== 'device-link') {
      return res.status(400).json({ error: 'invalid pairing code' });
    }

    if (parsedPairing.deviceId !== deviceId || parsedPairing.deviceType !== deviceType) {
      return res.status(400).json({ error: 'pairing code does not match device' });
    }

    const phone = parsePhone(req.body.phone);
    const password = typeof req.body.password === 'string' ? req.body.password : '';

    if (!password) {
      return res.status(400).json({ error: 'password is required' });
    }

    const user = await authenticateUser(phone, password);

    await Device.findOneAndUpdate(
      { deviceId },
      {
        userId: user._id,
        deviceId,
        deviceType,
        pairedAt: new Date(),
        isPrimary: false,
        isActive: true,
      },
      { upsert: true, new: true }
    );

    const access = signToken({ sub: user._id, role: user.role, deviceId }, process.env.JWT_SECRET);
    const refresh = signToken({ sub: user._id, deviceId }, process.env.JWT_REFRESH_SECRET, '30d');

    return res.json({
      access,
      refresh,
      device: {
        deviceId,
        deviceType,
        pairedAt: new Date().toISOString(),
        isPrimary: false,
      },
      user: {
        id: user._id,
        name: user.name,
        phone: user.phone,
        role: user.role,
      },
    });
  } catch (err) {
    if (err.message === 'invalid credentials') {
      return res.status(401).json({ error: 'invalid credentials' });
    }

    if (err.message === 'phone is required' || err.message === 'phone must be a valid international number') {
      return res.status(400).json({ error: err.message });
    }

    return res.status(400).json({ error: err.message });
  }
}

async function logoutDevice(req, res) {
  try {
    if (!req.body.device_id || typeof req.body.device_id !== 'string') {
      return res.status(400).json({ error: 'device_id is required' });
    }

    const device = await Device.findOneAndUpdate(
      { deviceId: req.body.device_id },
      { isActive: false },
      { new: true }
    );

    if (!device) {
      return res.status(404).json({ error: 'device not found' });
    }

    return res.json({ ok: true, deviceId: device.deviceId, isActive: false });
  } catch (err) {
    return res.status(500).json({ error: 'failed to log out device' });
  }
}

module.exports = { issuePairingCode, linkDevice, logoutDevice };
