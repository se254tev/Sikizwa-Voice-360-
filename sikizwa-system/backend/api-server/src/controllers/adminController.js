const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const User = require('../models/User');

function signToken(payload, secret, expiresIn = '60m') {
  return jwt.sign(payload, secret, { expiresIn });
}

function buildAdminResponse(user) {
  return {
    id: user._id,
    fullName: user.fullName,
    phoneNumber: user.phoneNumber || user.phone,
    email: user.email,
    nationalId: user.nationalId,
    role: user.role,
    createdAt: user.createdAt,
    updatedAt: user.updatedAt,
  };
}

async function signup(req, res, next) {
  try {
    const { fullName, phoneNumber, email, nationalId, password } = req.body;

    const existing = await User.findOne({
      $or: [
        { email },
        { phoneNumber },
        { nationalId },
      ],
    });

    if (existing) {
      return res.status(409).json({ success: false, message: 'An admin with that email, phone number, or national ID already exists' });
    }

    const passwordHash = await bcrypt.hash(password, 12);

    const admin = await User.create({
      fullName,
      phoneNumber,
      phone: phoneNumber,
      email,
      nationalId,
      passwordHash,
      role: 'admin',
    });

    const token = signToken({ sub: admin._id, role: admin.role }, process.env.JWT_SECRET, process.env.JWT_EXPIRES_IN || '60m');

    return res.status(201).json({
      success: true,
      message: 'Admin account created successfully',
      token,
      admin: buildAdminResponse(admin),
    });
  } catch (err) {
    if (err.code === 11000) {
      return res.status(409).json({ success: false, message: 'An admin with that email, phone number, or national ID already exists' });
    }

    return next(err);
  }
}

async function login(req, res, next) {
  try {
    const { identifier, password } = req.body;
    const user = await User.findOne({
      $or: [
        { email: identifier },
        { phoneNumber: identifier },
        { phone: identifier },
      ],
    });

    if (!user || user.role !== 'admin') {
      return res.status(401).json({ success: false, message: 'Invalid admin credentials' });
    }

    const validPassword = await bcrypt.compare(password, user.passwordHash || '');
    if (!validPassword) {
      return res.status(401).json({ success: false, message: 'Invalid admin credentials' });
    }

    const token = signToken({ sub: user._id, role: user.role }, process.env.JWT_SECRET, process.env.JWT_EXPIRES_IN || '60m');

    return res.json({
      success: true,
      message: 'Admin login successful',
      token,
      admin: buildAdminResponse(user),
    });
  } catch (err) {
    return next(err);
  }
}

async function logout(req, res, next) {
  try {
    return res.json({ success: true, message: 'Admin logged out successfully' });
  } catch (err) {
    return next(err);
  }
}

async function profile(req, res, next) {
  try {
    if (!req.user || req.user.role !== 'admin') {
      return res.status(403).json({ success: false, message: 'Access denied' });
    }

    return res.json({
      success: true,
      admin: buildAdminResponse(req.user),
    });
  } catch (err) {
    return next(err);
  }
}

module.exports = { signup, login, logout, profile };