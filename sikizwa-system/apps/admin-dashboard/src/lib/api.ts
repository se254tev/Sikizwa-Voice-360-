import axios from 'axios';

const api = axios.create({
  baseURL: import.meta.env.VITE_API_URL || 'http://localhost:4000/api',
  withCredentials: true
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
