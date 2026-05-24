const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const bcrypt = require('bcrypt');
const Device = require('../models/Device');
const User = require('../models/User');

function signToken(payload, secret, expiresIn = '15m') {
  return jwt.sign(payload, secret, { expiresIn });
}

function normalizeRole(role) {
  const allowed = ['user', 'counsellor', 'admin', 'responder', 'other'];
  return allowed.includes(role) ? role : 'other';
}

function normalizePhone(value) {
  const phone = typeof value === 'string' ? value.trim() : '';
  if (!/^\+?[0-9]{7,15}$/.test(phone)) {
    throw new Error('phone must be a valid international number');
  }
  return phone;
}

function normalizeDeviceType(value) {
  if (!value) {
    return null;
  }

  const normalized = value.toString().trim();
  if (!['phone', 'tablet', 'tv', 'watch'].includes(normalized)) {
    throw new Error('device_type must be phone, tablet, tv, or watch');
  }
  return normalized;
}

function normalizeContact(contact) {
  if (!contact || typeof contact !== 'object') {
    throw new Error('emergencyContacts must contain valid contacts');
  }

  const name = String(contact.name || '').trim();
  const phone = String(contact.phone || '').trim();
  const relationship = String(contact.relationship || '').trim();
  const type = ['personal', 'professional', 'guardian'].includes(contact.type) ? contact.type : 'personal';

  if (!name || !phone || !relationship) {
    throw new Error('emergencyContacts must contain complete contact details');
  }

  if (!/^\+?[0-9]{7,15}$/.test(phone)) {
    throw new Error('emergencyContacts phone numbers must be valid international numbers');
  }

  return { name, phone, relationship, type };
}

function normalizeContacts(contacts) {
  if (!Array.isArray(contacts) || contacts.length < 1) {
    throw new Error('emergencyContacts must contain at least one contact');
  }

  return contacts.map(normalizeContact);
}

async function upsertDevice(deviceId, deviceType, userId) {
  if (!deviceId || !deviceType) {
    return null;
  }

  await Device.findOneAndUpdate(
    { deviceId },
    {
      userId,
      deviceId,
      deviceType,
      pairedAt: new Date(),
      isPrimary: false,
      isActive: true,
    },
    { upsert: true, new: true }
  );

  return true;
}

async function anonymousLogin(req, res, next) {
  try {
    const anonId = 'anon_' + crypto.randomBytes(16).toString('hex');
    const user = await User.create({ anonymousId: anonId });
    const access = signToken({ sub: user._id, role: user.role }, process.env.JWT_SECRET);
    const refresh = signToken({ sub: user._id, role: user.role }, process.env.JWT_REFRESH_SECRET, '30d');
    res.json({ access, refresh, anonymousId: anonId });
  } catch (err) {
    next(err);
  }
}

async function register(req, res, next) {
  try {
    const {
      fullName,
      phone,
      password,
      role = 'other',
      email,
      emergencyContacts,
      bloodGroup,
      allergies,
      medicalConditions,
      location,
      device_id,
      device_type,
    } = req.body;

    if (!fullName || !phone || !password) {
      return res.status(400).json({ error: 'fullName, phone, and password are required' });
    }

    const normalizedPhone = normalizePhone(phone);
    const normalizedType = normalizeDeviceType(device_type);
    const normalizedContacts = normalizeContacts(emergencyContacts);
    const normalizedEmail = typeof email === 'string' && email.trim().length > 0 ? email.trim() : undefined;

    const hash = await bcrypt.hash(password, 10);
    const user = await User.create({
      name: fullName,
      fullName,
      phone: normalizedPhone,
      username: normalizedPhone,
      passwordHash: hash,
      role: normalizeRole(role),
      email: normalizedEmail,
      emergencyContacts: normalizedContacts,
      medicalProfile: {
        bloodGroup: bloodGroup?.trim(),
        allergies: allergies?.trim(),
        medicalConditions: medicalConditions?.trim(),
      },
      location: location?.trim(),
    });

    await upsertDevice(device_id, normalizedType, user._id);

    const access = signToken({ sub: user._id, role: user.role, deviceId: device_id || undefined }, process.env.JWT_SECRET);
    const refresh = signToken(
      { sub: user._id, role: user.role, deviceId: device_id || undefined },
      process.env.JWT_REFRESH_SECRET,
      '30d'
    );

    return res.json({ access, refresh });
  } catch (err) {
    if (err.message === 'phone must be a valid international number') {
      return res.status(400).json({ error: err.message });
    }

    if (err.message.includes('emergencyContacts')) {
      return res.status(400).json({ error: err.message });
    }

    if (err.code === 11000) {
      return res.status(409).json({ error: 'phone or email is already registered' });
    }

    return next(err);
  }
}

async function login(req, res, next) {
  try {
    const { identifier, password, device_id, device_type } = req.body;
    if (!identifier || !password) {
      return res.status(400).json({ error: 'identifier and password are required' });
    }

    const normalizedType = normalizeDeviceType(device_type);
    const user = await User.findOne({
      $or: [{ phone: identifier }, { username: identifier }, { email: identifier }],
    });

    if (!user) {
      return res.status(401).json({ error: 'invalid credentials' });
    }

    const ok = await bcrypt.compare(password, user.passwordHash || '');
    if (!ok) {
      return res.status(401).json({ error: 'invalid credentials' });
    }

    await upsertDevice(device_id, normalizedType, user._id);

    const access = signToken({ sub: user._id, role: user.role, deviceId: device_id || undefined }, process.env.JWT_SECRET);
    const refresh = signToken(
      { sub: user._id, role: user.role, deviceId: device_id || undefined },
      process.env.JWT_REFRESH_SECRET,
      '30d'
    );

    return res.json({ access, refresh });
  } catch (err) {
    if (err.message === 'device_type must be phone, tablet, tv, or watch') {
      return res.status(400).json({ error: err.message });
    }

    return next(err);
  }
}

async function refreshToken(req, res, next) {
  try {
    const { token } = req.body;
    if (!token) {
      return res.status(400).json({ error: 'token required' });
    }

    const payload = jwt.verify(token, process.env.JWT_REFRESH_SECRET);
    const access = signToken(
      { sub: payload.sub, role: payload.role, deviceId: payload.deviceId },
      process.env.JWT_SECRET
    );

    return res.json({ access });
  } catch (err) {
    next(err);
  }
}

module.exports = { anonymousLogin, register, login, refreshToken };
