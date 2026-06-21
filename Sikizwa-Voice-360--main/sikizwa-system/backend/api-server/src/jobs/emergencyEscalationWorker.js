const mongoose = require('mongoose');
const { connectDB } = require('../config/db');
const Emergency = require('../models/Emergency');
const Notification = require('../models/Notification');

async function escalateEmergencies() {
  await connectDB(process.env.MONGO_ATLAS_URI || process.env.MONGO_URI);
  const pending = await Emergency.find({ status: 'pending' }).sort({ createdAt: 1 }).limit(50);
  for (const emergency of pending) {
    if (emergency.severity === 'emergency') {
      emergency.status = 'dispatched';
      await emergency.save();
      await Notification.create({
        type: 'escalation',
        title: 'Emergency escalation',
        body: 'A high-risk emergency has been escalated.',
        data: { emergencyId: emergency._id }
      });
    }
  }
  process.exit(0);
}

escalateEmergencies().catch(err => {
  console.error(err);
  process.exit(1);
});