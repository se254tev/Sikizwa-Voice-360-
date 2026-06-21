# Sikizwa Voice 360°

Enterprise-grade monorepo for the Sikizwa Voice 360° platform.

## Repository layout

- `apps/`
  - `mobile-app/` — Flutter mobile application
  - `admin-dashboard/` — React admin dashboard
  - `ai-service/` — Python FastAPI AI microservice
- `backend/`
  - `api-server/` — Node.js Express API server
- `infrastructure/`
  - `docker/` — container orchestration files
  - `nginx/` — reverse proxy and routing config
  - `render/` — Render deployment manifests
  - `vercel/` — Vercel deployment configuration
  - `monitoring/` — monitoring and observability plans
- `docs/` — architecture and runbooks
- `scripts/` — helper scripts

## Getting started

### Local services

```bash
cd "c:\Users\SHARON Otunga\Desktop\Sikizwa Voice 360°\sikizwa-system"
docker compose up --build
```

### App-specific development

- Mobile app: `cd apps/mobile-app && flutter pub get && flutter run`
- Dashboard: `cd apps/admin-dashboard && npm install && npm run dev`
- Backend: `cd backend/api-server && npm install && npm run dev`
- AI service: `cd apps/ai-service && python -m pip install -r requirements.txt && uvicorn app.main:app --host 0.0.0.0 --port 8000`

## Deployment

- Backend is ready for Render via `backend/api-server/render.yaml`
- Dashboard is ready for Vercel via `apps/admin-dashboard/vercel.json`
- AI service is Docker-ready and can be deployed as a container

## Notes

- Keep environment secrets in service-level `.env` files or deployment environment variables.
- Root `docker-compose.yml` uses the new service paths.
- `infrastructure/` contains deployment and proxy configs organized by provider.
