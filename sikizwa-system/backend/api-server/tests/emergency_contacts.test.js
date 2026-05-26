const test = require('node:test');
const assert = require('node:assert/strict');

const userController = require('../src/controllers/userController');
const User = require('../src/models/User');

test('saveEmergencyContacts normalizes and stores emergency contacts', async () => {
  const originalFindByIdAndUpdate = User.findByIdAndUpdate;

  const savedPayload = [
    {
      name: 'Amina Ndlovu',
      phone: '+27821234567',
      relationship: 'Sister',
      type: 'personal',
    },
    {
      name: 'Thandi Maseko',
      phone: '0821234567',
      relationship: 'Friend',
      type: 'personal',
    },
  ];

  let receivedUpdate = null;

  User.findByIdAndUpdate = async (userId, update, options) => {
    receivedUpdate = { userId, update, options };

    return {
      emergencyContacts: savedPayload,
    };
  };

  const res = {
    statusCode: null,
    payload: null,
    status(code) {
      this.statusCode = code;
      return this;
    },
    json(payload) {
      this.payload = payload;
      return this;
    },
  };

  try {
    await userController.saveEmergencyContacts(
      {
        user: {
          _id: 'user-1',
        },
        body: {
          contacts: [
            {
              name: ' Amina Ndlovu ',
              phone: ' +27821234567 ',
              relationship: ' Sister ',
              type: 'personal',
            },
            {
              name: 'Thandi Maseko',
              phone: '0821234567',
              relationship: 'Friend',
              type: 'personal',
            },
          ],
        },
      },
      res,
      () => {
        throw new Error('next should not be called');
      }
    );
  } finally {
    User.findByIdAndUpdate = originalFindByIdAndUpdate;
  }

  assert.deepStrictEqual(receivedUpdate.update.$set.emergencyContacts, savedPayload);
  assert.equal(res.statusCode, null);
  assert.deepStrictEqual(res.payload.success, true);
  assert.deepStrictEqual(res.payload.data.contacts, savedPayload);
});
