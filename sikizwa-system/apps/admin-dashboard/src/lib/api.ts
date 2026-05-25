import axios from 'axios';

const api = axios.create({
  baseURL: import.meta.env.VITE_API_URL || 'http://localhost:4000/api',
  withCredentials: true
});

const ACCESS_TOKEN_KEY = 'admin_access_token';
const envToken = typeof import.meta.env.VITE_ADMIN_TOKEN === 'string' ? import.meta.env.VITE_ADMIN_TOKEN.trim() : '';

api.interceptors.request.use((config) => {
  const storedToken = window.localStorage.getItem(ACCESS_TOKEN_KEY)?.trim() || '';
  const token = envToken || storedToken;

  if (token) {
    config.headers = config.headers ?? {};
    config.headers.Authorization = `Bearer ${token}`;
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

export function saveAdminToken(token) {
  window.localStorage.setItem(ACCESS_TOKEN_KEY, token);
}

export function clearAdminToken() {
  window.localStorage.removeItem(ACCESS_TOKEN_KEY);
}

export function getAdminToken() {
  return window.localStorage.getItem(ACCESS_TOKEN_KEY)?.trim() || '';
}
