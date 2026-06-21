const { asyncHandler } = require('../utils/asyncHandler');
const { throwError } = require('../utils/throwError');
const { VALIDATION_ERRORS, NOT_FOUND_ERRORS } = require('../utils/errorMessages');

const getExampleResource = asyncHandler(async (req, res) => {
  const { id } = req.params;

  if (!id) {
    throwError({
      statusCode: 400,
      message: VALIDATION_ERRORS.missingFields.message,
      errorCode: VALIDATION_ERRORS.missingFields.errorCode,
      details: { field: 'id' },
    });
  }

  if (id === 'missing') {
    throwError({
      statusCode: 404,
      message: NOT_FOUND_ERRORS.resourceNotFound.message,
      errorCode: NOT_FOUND_ERRORS.resourceNotFound.errorCode,
      details: { resource: 'example resource' },
    });
  }

  res.status(200).json({
    success: true,
    data: {
      id,
      message: 'Example resource loaded successfully.',
    },
  });
});

module.exports = {
  getExampleResource,
};
