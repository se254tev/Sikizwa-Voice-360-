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
  const res = await api.get('/reports');
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
