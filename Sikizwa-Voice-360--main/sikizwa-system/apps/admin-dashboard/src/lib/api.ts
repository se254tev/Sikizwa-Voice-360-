import axios from 'axios';

const api = axios.create({
  baseURL: import.meta.env.VITE_API_URL || 'http://197.139.6.117/api',
  withCredentials: true
});

const envToken = typeof import.meta.env.VITE_ADMIN_TOKEN === 'string' ? import.meta.env.VITE_ADMIN_TOKEN.trim() : '';

// In-memory CSRF token (does not persist to storage)
let csrfToken: string | null = null;

/**
 * Fetch CSRF token from the server at `/web/csrf-token`.
 * Uses `fetch` with `credentials: 'include'` as required.
 * Call this before making state-changing requests under `/web/*`.
 */
export async function fetchCsrfToken(fetchUrl?: string) {
  const url = fetchUrl || '/web/csrf-token';
  const res = await fetch(url, { credentials: 'include' });
  if (!res.ok) throw new Error(`Failed to fetch CSRF token: ${res.status}`);
  const body = await res.json();
  // Expecting shape: { csrfToken: '...' } or { token: '...' }
  csrfToken = (body && (body.csrfToken || body.token)) || null;
  return csrfToken;
}

export function getCsrfToken() {
  return csrfToken;
}

api.interceptors.request.use((config) => {
  // Authorization via httpOnly cookie (set by backend during login/signup)
  // Frontend does not need to manually add token to headers
  // Only add Authorization header if VITE_ADMIN_TOKEN is set (for testing/env override)
  if (envToken) {
    config.headers = config.headers ?? {};
    config.headers.Authorization = `Bearer ${envToken}`;
  }

  // Ensure credentials are included on all requests (includes cookies)
  config.withCredentials = true;

  // Attach CSRF token for state-changing requests under /web/*
  try {
    const method = (config.method || '').toLowerCase();
    const isStateChanging = method === 'post' || method === 'put' || method === 'delete' || method === 'patch';
    const urlPath = config.url || '';

    const matchesWebPath = /^\/web(\/|$)/.test(urlPath) || (config.baseURL && new URL(urlPath, config.baseURL).pathname.startsWith('/web'));

    if (isStateChanging && matchesWebPath && csrfToken) {
      config.headers = config.headers ?? {};
      config.headers['x-csrf-token'] = csrfToken;
    }
  } catch (e) {
    // ignore URL parsing errors; don't break requests
  }

  return config;
});

export async function fetchAnalyticsOverview() {
  const res = await api.get('/analytics/overview');
  return res.data;
}

export async function fetchReportTrends() {
  const res = await api.get('/analytics/reports/trends');
  return res.data;
}

export async function fetchReports() {
  const res = await api.get('/admin/reports');
  return Array.isArray(res.data?.data?.items) ? res.data.data.items : [];
}

export async function updateReportStatus(reportId: string, status: string) {
  const res = await api.patch(`/admin/reports/${reportId}/status`, { status });
  return res.data;
}

export async function deleteReport(reportId: string) {
  const res = await api.delete(`/admin/reports/${reportId}`);
  return res.data;
}

export async function fetchEmergencies() {
  const res = await api.get('/emergencies');
  return res.data;
}

export async function fetchCounsellors() {
  const res = await api.get('/counsellors');
  return res.data;
}

export async function adminSignup(data) {
  const res = await api.post('/admin/signup', data);
  return res.data;
}

export async function adminLogin(identifier, password) {
  const res = await api.post('/admin/login', { identifier, password });
  return res.data;
}

export async function adminLogout() {
  const res = await api.post('/admin/logout');
  return res.data;
}

export async function fetchAdminProfile() {
  const res = await api.get('/admin/profile');
  return res.data;
}
