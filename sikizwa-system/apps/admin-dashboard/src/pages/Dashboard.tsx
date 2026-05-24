import { useEffect, useMemo, useState } from 'react';
import {
  CartesianGrid,
  Line,
  LineChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis
} from 'recharts';
import { fetchAnalyticsOverview, fetchEmergencies, fetchReportTrends, fetchReports } from '../lib/api';

type TrendPoint = {
  label: string;
  count: number;
};

type ActivityEntry = {
  id: string;
  title: string;
  detail: string;
  timestamp: string;
  badge: string;
};

type OverviewData = {
  reportCount?: number;
  emergencyCount?: number;
  recentAudits?: unknown[];
};

function formatTimestamp(value: string | Date | undefined) {
  if (!value) {
    return 'Just now';
  }

  const parsed = value instanceof Date ? value : new Date(value);

  if (Number.isNaN(parsed.getTime())) {
    return 'Just now';
  }

  return parsed.toLocaleString();
}

function normalizeTrendData(rawData: unknown): TrendPoint[] {
  if (!Array.isArray(rawData)) {
    return [];
  }

  return rawData
    .map((entry: any, index: number) => {
      if (!entry) {
        return null;
      }

      const label = entry.label || entry._id || entry.month || entry.date || `Week ${index + 1}`;
      const count = Number(entry.count ?? entry.value ?? entry.total ?? entry.reports ?? 0);

      if (!label) {
        return null;
      }

      return {
        label: String(label),
        count: Number.isFinite(count) ? count : 0
      };
    })
    .filter(Boolean) as TrendPoint[];
}

function normalizeActivityEntries(rawData: unknown): ActivityEntry[] {
  if (!Array.isArray(rawData)) {
    return [];
  }

  return rawData
    .map((entry: any, index: number) => {
      const action = String(entry?.action || entry?.type || entry?.event || '').toLowerCase();
      const label =
        action.includes('emergency')
          ? 'Emergency detected'
          : action.includes('assign') || action.includes('counsellor')
            ? 'Counsellor assigned'
            : action.includes('alert') || action.includes('system')
              ? 'System alert'
              : 'Incident created';

      return {
        id: entry?._id || `log-${index}`,
        title: label,
        detail: entry?.description || entry?.notes || entry?.message || 'No details available.',
        timestamp: formatTimestamp(entry?.createdAt || entry?.timestamp),
        badge:
          action.includes('emergency')
            ? 'Critical'
            : action.includes('assign') || action.includes('counsellor')
              ? 'Assigned'
              : action.includes('alert') || action.includes('system')
                ? 'Synced'
                : 'Live'
      };
    })
    .filter((entry) => entry.title && entry.detail);
}

function normalizeOverview(rawData: unknown): OverviewData | null {
  if (!rawData || typeof rawData !== 'object') {
    return null;
  }

  const value = rawData as Record<string, unknown>;

  return {
    reportCount: typeof value.reportCount === 'number' ? value.reportCount : undefined,
    emergencyCount: typeof value.emergencyCount === 'number' ? value.emergencyCount : undefined,
    recentAudits: Array.isArray(value.recentAudits) ? value.recentAudits : []
  };
}

function SkeletonCard() {
  return (
    <div className="rounded-3xl border border-slate-200 bg-white p-6 shadow-sm">
      <div className="h-3 w-24 animate-pulse rounded-full bg-slate-200" />
      <div className="mt-4 h-9 w-20 animate-pulse rounded bg-slate-200" />
    </div>
  );
}

function SkeletonChart() {
  return (
    <div className="mt-6 h-80 rounded-2xl bg-slate-50 p-4">
      <div className="h-full animate-pulse rounded-2xl bg-slate-200" />
    </div>
  );
}

function DashboardPage() {
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [overview, setOverview] = useState<OverviewData | null>(null);
  const [trends, setTrends] = useState<TrendPoint[]>([]);
  const [reports, setReports] = useState<any[]>([]);
  const [emergencies, setEmergencies] = useState<any[]>([]);

  const loadDashboardData = async (isBackground = false) => {
    if (!isBackground) {
      setLoading(true);
    } else {
      setRefreshing(true);
    }

    const [overviewResult, trendsResult, reportsResult, emergenciesResult] = await Promise.allSettled([
      fetchAnalyticsOverview(),
      fetchReportTrends(),
      fetchReports(),
      fetchEmergencies()
    ]);

    const liveOverview = overviewResult.status === 'fulfilled' ? normalizeOverview(overviewResult.value) : null;
    const liveTrends = trendsResult.status === 'fulfilled' ? normalizeTrendData(trendsResult.value?.trends ?? trendsResult.value) : [];
    const liveReports = reportsResult.status === 'fulfilled' && Array.isArray(reportsResult.value) ? reportsResult.value : [];
    const liveEmergencies = emergenciesResult.status === 'fulfilled' && Array.isArray(emergenciesResult.value) ? emergenciesResult.value : [];

    const hasFailures = [overviewResult, trendsResult, reportsResult, emergenciesResult].some((result) => result.status === 'rejected');
    const hasLiveData = Boolean(liveOverview) || liveTrends.length > 0 || liveReports.length > 0 || liveEmergencies.length > 0;

    setOverview(liveOverview);
    setReports(liveReports);
    setEmergencies(liveEmergencies);
    setTrends(liveTrends);
    setError(hasLiveData ? null : hasFailures ? 'Live dashboard data is temporarily unavailable.' : null);

    if (!isBackground) {
      setLoading(false);
    }
    setRefreshing(false);
  };

  useEffect(() => {
    loadDashboardData();

    const interval = window.setInterval(() => {
      loadDashboardData(true);
    }, 45000);

    return () => window.clearInterval(interval);
  }, []);

  const recentLogs = useMemo<ActivityEntry[]>(() => normalizeActivityEntries(overview?.recentAudits), [overview]);
  const reportCount = overview?.reportCount ?? reports.length;
  const emergencyCount = overview?.emergencyCount ?? emergencies.length;
  const recentLogsCount = overview?.recentAudits?.length ?? recentLogs.length;
  const hasRecentLogs = recentLogs.length > 0;

  return (
    <div className="space-y-6">
      <header className="flex flex-wrap items-end justify-between gap-4">
        <div>
          <p className="text-sm font-semibold uppercase tracking-[0.2em] text-maroon">Realtime analytics</p>
          <h1 className="mt-2 text-3xl font-bold text-darkblue">Dashboard overview</h1>
          <p className="mt-2 text-slate-500">
            Monitor incidents, emergency response, and the latest system activity in one place.
          </p>
        </div>

        <div className="flex items-center gap-3 text-sm text-slate-500">
          <span className="rounded-full bg-softgreen/20 px-3 py-1 text-softgreen">
            {refreshing ? 'Refreshing…' : 'Live updates active'}
          </span>
          {error ? (
            <span className="rounded-full bg-amber-100 px-3 py-1 text-amber-700">{error}</span>
          ) : null}
        </div>
      </header>

      <div className="grid gap-6 md:grid-cols-3">
        {loading ? (
          <>
            <SkeletonCard />
            <SkeletonCard />
            <SkeletonCard />
          </>
        ) : (
          <>
            <div className="rounded-3xl border border-slate-200 bg-white p-6 shadow-sm">
              <h2 className="text-sm uppercase tracking-[0.2em] text-slate-400">Reports</h2>
              <p className="mt-4 text-3xl font-semibold text-maroon">{reportCount}</p>
              <p className="mt-2 text-sm text-slate-500">{reports.length > 0 ? 'Live report volume' : 'No live report data available'}</p>
            </div>
            <div className="rounded-3xl border border-slate-200 bg-white p-6 shadow-sm">
              <h2 className="text-sm uppercase tracking-[0.2em] text-slate-400">Emergencies</h2>
              <p className="mt-4 text-3xl font-semibold text-darkblue">{emergencyCount}</p>
              <p className="mt-2 text-sm text-slate-500">{emergencies.length > 0 ? 'Current incident focus' : 'No live emergency data available'}</p>
            </div>
            <div className="rounded-3xl border border-slate-200 bg-white p-6 shadow-sm">
              <h2 className="text-sm uppercase tracking-[0.2em] text-slate-400">Recent logs</h2>
              <p className="mt-4 text-3xl font-semibold text-softgreen">{recentLogsCount}</p>
              <p className="mt-2 text-sm text-slate-500">{hasRecentLogs ? 'Latest activity feed' : 'No data available'}</p>
            </div>
          </>
        )}
      </div>

      <section className="rounded-3xl border border-slate-200 bg-white p-6 shadow-sm">
        <div className="flex flex-wrap items-center justify-between gap-4">
          <div>
            <h2 className="text-xl font-semibold text-darkblue">Report Trends</h2>
            <p className="text-sm text-slate-500">Weekly report volume and response activity.</p>
          </div>
          <span className="rounded-full bg-maroon/10 px-3 py-1 text-sm text-maroon">Auto-refresh every 45s</span>
        </div>

        {loading ? (
          <SkeletonChart />
        ) : trends.length > 0 ? (
          <div className="mt-6 h-80">
            <ResponsiveContainer width="100%" height="100%">
              <LineChart data={trends}>
                <CartesianGrid strokeDasharray="3 3" stroke="#E2E8F0" />
                <XAxis dataKey="label" tickLine={false} axisLine={false} />
                <YAxis allowDecimals={false} tickLine={false} axisLine={false} />
                <Tooltip />
                <Line type="monotone" dataKey="count" stroke="#7B1F3C" strokeWidth={3} dot={{ r: 4 }} />
              </LineChart>
            </ResponsiveContainer>
          </div>
        ) : (
          <div className="mt-6 rounded-2xl border border-dashed border-slate-200 px-4 py-10 text-center text-slate-500">
            No data available
          </div>
        )}
      </section>

      <section className="rounded-3xl border border-slate-200 bg-white p-6 shadow-sm">
        <div className="flex items-center justify-between gap-4">
          <div>
            <h2 className="text-xl font-semibold text-darkblue">Recent logs</h2>
            <p className="text-sm text-slate-500">Latest activity from incidents, alerts, and assignments.</p>
          </div>
        </div>

        {loading ? (
          <div className="mt-6 space-y-3">
            {[1, 2, 3].map((item) => (
              <div key={item} className="rounded-2xl border border-slate-200 bg-slate-50 p-4">
                <div className="h-4 w-32 animate-pulse rounded-full bg-slate-200" />
                <div className="mt-3 h-3 w-full animate-pulse rounded bg-slate-200" />
              </div>
            ))}
          </div>
        ) : hasRecentLogs ? (
          <div className="mt-6 space-y-3">
            {recentLogs.map((entry) => (
              <div key={entry.id} className="rounded-2xl border border-slate-200 bg-slate-50 p-4">
                <div className="flex flex-wrap items-center justify-between gap-3">
                  <div>
                    <p className="text-sm font-semibold text-darkblue">{entry.title}</p>
                    <p className="mt-1 text-sm text-slate-600">{entry.detail}</p>
                  </div>
                  <div className="flex items-center gap-3 text-sm">
                    <span className="rounded-full bg-maroon/10 px-3 py-1 text-maroon">{entry.badge}</span>
                    <span className="text-slate-500">{entry.timestamp}</span>
                  </div>
                </div>
              </div>
            ))}
          </div>
        ) : (
          <div className="mt-6 rounded-2xl border border-dashed border-slate-200 px-4 py-10 text-center text-slate-500">
            No data available
          </div>
        )}
      </section>
    </div>
  );
}

export default DashboardPage;
