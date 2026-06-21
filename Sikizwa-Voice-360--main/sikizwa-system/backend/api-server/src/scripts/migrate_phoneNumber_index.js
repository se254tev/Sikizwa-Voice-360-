require('dotenv').config();
const mongoose = require('mongoose');
const logger = require('../config/logger');

const uri = process.env.MONGO_URI || process.env.MONGO_ATLAS_URI;

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
    const countNull = await col.countDocuments({ phoneNumber: null });
    const countMissing = await col.countDocuments({ phoneNumber: { $exists: false } });
    const countEmpty = await col.countDocuments({ phoneNumber: '' });

    console.log('Users with phoneNumber === null :', countNull);
    console.log('Users with phoneNumber missing   :', countMissing);
    console.log("Users with phoneNumber == ''      :", countEmpty);

    const apply = process.argv.includes('--apply');

    if (apply) {
      console.log('Applying cleanup: unsetting null or empty phoneNumber fields...');
      const unsetResultNull = await col.updateMany(
        { phoneNumber: null },
        { $unset: { phoneNumber: '' } }
      );
      const unsetResultEmpty = await col.updateMany(
        { phoneNumber: '' },
        { $unset: { phoneNumber: '' } }
      );
      console.log('Unset null count:', unsetResultNull.modifiedCount);
      console.log('Unset empty count:', unsetResultEmpty.modifiedCount);
    } else {
      console.log('Run with --apply to remove null/empty phoneNumber fields. No changes made.');
    }

    console.log('Creating partial unique index on phoneNumber...');
    try {
      await col.createIndex(
        { phoneNumber: 1 },
        {
          unique: true,
          partialFilterExpression: { phoneNumber: { $type: 'string' } },
          name: 'phoneNumber_partial_unique',
        }
      );
      console.log('Partial unique index created (or already exists)');
    } catch (err) {
      console.error('Failed creating index:', err.message || err);
      console.error('If index creation fails due to duplicates, run with --apply to clean null/empty values and re-run.');
      process.exitCode = 2;
    }
  } finally {
    await mongoose.disconnect();
  }
}

main().catch((err) => {
  console.error('Migration failed:', err);
  process.exit(1);
});
