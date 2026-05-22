const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const bcrypt = require('bcrypt');
const User = require('../models/User');

function signToken(payload, secret, expiresIn='15m'){
  return jwt.sign(payload, secret, { expiresIn });
}

async function anonymousLogin(req, res, next){
  try{
    const anonId = 'anon_' + crypto.randomBytes(16).toString('hex');
    const user = await User.create({ anonymousId: anonId });
    const access = signToken({ sub: user._id, role: user.role }, process.env.JWT_SECRET);
    const refresh = signToken({ sub: user._id }, process.env.JWT_REFRESH_SECRET, '30d');
    res.json({ access, refresh, anonymousId: anonId });
  }catch(err){ next(err); }
}

async function register(req, res, next){
  try{
    const { username, password, role='user' } = req.body;
    if(!username || !password) return res.status(400).json({ error: 'username and password required' });
    const hash = await bcrypt.hash(password, 10);
    const user = await User.create({ username, passwordHash: hash, role });
    const access = signToken({ sub: user._id, role: user.role }, process.env.JWT_SECRET);
    const refresh = signToken({ sub: user._id }, process.env.JWT_REFRESH_SECRET, '30d');
    res.json({ access, refresh });
  }catch(err){ next(err); }
}

async function login(req, res, next){
  try{
    const { username, password } = req.body;
    const user = await User.findOne({ username });
    if(!user) return res.status(401).json({ error: 'invalid' });
    const ok = await bcrypt.compare(password, user.passwordHash || '');
    if(!ok) return res.status(401).json({ error: 'invalid' });
    const access = signToken({ sub: user._id, role: user.role }, process.env.JWT_SECRET);
    const refresh = signToken({ sub: user._id }, process.env.JWT_REFRESH_SECRET, '30d');
    res.json({ access, refresh });
  }catch(err){ next(err); }
}

async function refreshToken(req, res, next){
  try{
    const { token } = req.body;
    if(!token) return res.status(400).json({ error: 'token required' });
    const payload = jwt.verify(token, process.env.JWT_REFRESH_SECRET);
    const access = signToken({ sub: payload.sub }, process.env.JWT_SECRET);
    res.json({ access });
  }catch(err){ next(err); }
}

module.exports = { anonymousLogin, register, login, refreshToken };
