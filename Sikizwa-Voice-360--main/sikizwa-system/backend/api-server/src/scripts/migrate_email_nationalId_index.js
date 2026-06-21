require('dotenv').config();
const mongoose = require('mongoose');
const logger = require('../config/logger');

const uri = process.env.MONGO_URI || process.env.MONGO_ATLAS_URI;

async function countDuplicates(col, field) {
  const pipeline = [
    { $match: { [field]: { $type: 'string' } } },
    { $group: { _id: `$${field}`, count: { $sum: 1 } } },
    { $match: { count: { $gt: 1 } } },
    { $sort: { count: -1 } },
    { $limit: 20 },
  ];

  const dupes = await col.aggregate(pipeline).toArray();
  return dupes;
}

async function main() {
  if (!uri) {
    console.error('MONGO_URI or MONGO_ATLAS_URI must be set in environment');
    process.exit(1);
  }

  await mongoose.connect(uri, {
    useNewUrlParser: true,
    useUnifiedTopology: true,
  });

  const col = mongoose.connection.collection('users');

  try {
    // Email counts
    const emailNull = await col.countDocuments({ email: null });
    const emailMissing = await col.countDocuments({ email: { $exists: false } });
    const emailEmpty = await col.countDocuments({ email: '' });
    console.log('email === null :', emailNull);
    console.log('email missing  :', emailMissing);
    console.log("email == ''     :", emailEmpty);

    // NationalId counts
    const nidNull = await col.countDocuments({ nationalId: null });
    const nidMissing = await col.countDocuments({ nationalId: { $exists: false } });
    const nidEmpty = await col.countDocuments({ nationalId: '' });
    console.log('nationalId === null :', nidNull);
    console.log('nationalId missing  :', nidMissing);
    console.log("nationalId == ''     :", nidEmpty);

    // Duplicate samples
    const dupEmails = await countDuplicates(col, 'email');
    const dupNids = await countDuplicates(col, 'nationalId');

    console.log('Sample duplicate emails (top 20):', dupEmails.slice(0, 10));
    console.log('Sample duplicate nationalIds (top 20):', dupNids.slice(0, 10));

    const apply = process.argv.includes('--apply');

    if (apply) {
      console.log('Applying cleanup: unsetting null or empty email and nationalId fields...');
      const unsetEmailNull = await col.updateMany({ email: null }, { $unset: { email: '' } });
      const unsetEmailEmpty = await col.updateMany({ email: '' }, { $unset: { email: '' } });
      console.log('Unset email null count:', unsetEmailNull.modifiedCount);
      console.log('Unset email empty count:', unsetEmailEmpty.modifiedCount);

      const unsetNidNull = await col.updateMany({ nationalId: null }, { $unset: { nationalId: '' } });
      const unsetNidEmpty = await col.updateMany({ nationalId: '' }, { $unset: { nationalId: '' } });
      console.log('Unset nationalId null count:', unsetNidNull.modifiedCount);
      console.log('Unset nationalId empty count:', unsetNidEmpty.modifiedCount);
    } else {
      console.log('Run with --apply to remove null/empty email and nationalId fields. No changes made.');
    }

    console.log('Creating partial unique index on email...');
    try {
      await col.createIndex(
        { email: 1 },
        {
          unique: true,
          partialFilterExpression: { email: { $type: 'string' } },
          name: 'email_partial_unique',
        }
      );
      console.log('Partial unique index for email created (or already exists)');
    } catch (err) {
      console.error('Failed creating email index:', err.message || err);
      console.error('If index creation fails due to duplicates, investigate duplicate values before applying cleanup.');
    }

    console.log('Creating partial unique index on nationalId...');
    try {
      await col.createIndex(
        { nationalId: 1 },
        {
          unique: true,
          partialFilterExpression: { nationalId: { $type: 'string' } },
          name: 'nationalId_partial_unique',
        }
      );
      console.log('Partial unique index for nationalId created (or already exists)');
    } catch (err) {
      console.error('Failed creating nationalId index:', err.message || err);
      console.error('If index creation fails due to duplicates, investigate duplicate values before applying cleanup.');
    }

  } finally {
    await mongoose.disconnect();
  }
}

main().catch((err) => {
  console.error('Migration failed:', err);
  process.exit(1);
});
