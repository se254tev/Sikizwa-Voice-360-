# Sikizwa Backend

Production-ready Node.js backend for Sikizwa Voice 360°.

Key features:
- Express API
- MongoDB Atlas via Mongoose
- JWT auth (access + refresh)
- Socket.io with Redis adapter
- Cloudinary uploads
- Render deployment config

Quick start (development):

1. Copy `.env.example` to `.env` and fill values (use MongoDB Atlas URI).
2. Install dependencies:

```bash
cd backend/api-server
npm install
```

3. Run locally:

```bash
npm run dev
```

Deploy to Render: `render.yaml` is included. Ensure the environment variables in Render match `.env` keys.

Security and production notes:
- Use HTTPS at the edge (Render provides TLS).
- Keep JWT secrets safe and rotate periodically.
- Use signed Cloudinary uploads for sensitive media.
