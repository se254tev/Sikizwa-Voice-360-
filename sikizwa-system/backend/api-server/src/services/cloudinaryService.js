const cloudinary = require('cloudinary').v2;
require('dotenv').config();

cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
  secure: true
});

async function uploadBuffer(buffer, options = {}){
  return new Promise((resolve, reject) => {
    cloudinary.uploader.upload_stream(options, (err, result) => {
      if(err) return reject(err);
      resolve(result);
    }).end(buffer);
  });
}

function buildUnsignedUploadPreset(){
  // recommend server-side signed uploads for security; placeholder util
  return process.env.CLOUDINARY_UPLOAD_PRESET || null;
}

module.exports = { cloudinary, uploadBuffer, buildUnsignedUploadPreset };
