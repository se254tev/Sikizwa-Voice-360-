const SupportChat = require('../models/SupportChat');
const AuditLog = require('../models/AuditLog');
const { getSocket } = require('../utils/socketRegistry');

async function createChat(req, res, next) {
  try {
    const { participantIds } = req.body;
    const chat = await SupportChat.create({
      participants: [req.user._id, ...participantIds],
      lastMessageAt: Date.now()
    });
    await AuditLog.create({
      actor: req.user._id,
      actorAnonId: req.user.anonymousId,
      action: 'create_support_chat',
      resource: 'SupportChat',
      resourceId: chat._id,
      ip: req.ip
    });
    res.status(201).json(chat);
  } catch (err) {
    next(err);
  }
}

async function listChats(req, res, next) {
  try {
    const chats = await SupportChat.find({ participants: req.user._id })
      .sort({ lastMessageAt: -1 })
      .limit(50);
    res.json(chats);
  } catch (err) {
    next(err);
  }
}

async function sendMessage(req, res, next) {
  try {
    const chat = await SupportChat.findById(req.params.id);
    if (!chat || !chat.participants.some(participant => participant.equals(req.user._id))) {
      return res.status(404).json({ error: 'chat not found' });
    }

    const message = {
      senderType: req.user.role === 'admin' || req.user.role === 'counsellor' ? 'counsellor' : 'user',
      senderRef: req.user._id,
      text: req.body.text,
      createdAt: Date.now()
    };

    chat.messages.push(message);
    chat.lastMessageAt = Date.now();
    await chat.save();

    const io = getSocket();
    if (io) {
      io.to(chat._id.toString()).emit('support.message', { chatId: chat._id, message });
    }

    await AuditLog.create({
      actor: req.user._id,
      actorAnonId: req.user.anonymousId,
      action: 'send_support_message',
      resource: 'SupportChat',
      resourceId: chat._id,
      ip: req.ip
    });

    res.json({ chatId: chat._id, message });
  } catch (err) {
    next(err);
  }
}

module.exports = { createChat, listChats, sendMessage };