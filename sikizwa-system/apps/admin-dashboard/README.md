# Sikizwa Dashboard

Admin dashboard for monitoring incidents, emergency response, counsellor operations, and analytics.

## Setup

1. Copy `.env.example` to `.env` and set `VITE_API_URL`.
2. Install dependencies:

```bash
cd apps/admin-dashboard
npm install
```

3. Run locally:

```bash
npm run dev
```

4. Build for production:

```bash
npm run build
```

## Vercel
- `vercel.json` is configured for static deployment.
- Use `VITE_API_URL` in Vercel environment variables.
