import { useEffect, useState } from 'react';
import { BarChart, Bar, XAxis, YAxis, ResponsiveContainer, Tooltip } from 'recharts';
import { fetchAnalyticsOverview, fetchReportTrends } from '../lib/api';

function DashboardPage() {
  const [overview, setOverview] = useState<any>(null);
  const [trends, setTrends] = useState<any[]>([]);

  useEffect(() => {
    fetchAnalyticsOverview().then(setOverview);
    fetchReportTrends().then((data) => setTrends(data.trends || []));
  }, []);

  return (
    <div className="space-y-6">
      <header className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-darkblue">Realtime Analytics</h1>
          <p className="text-slate-500">Insights into incidents, safe spaces, and emergency response.</p>
        </div>
      </header>

      <div className="grid gap-6 md:grid-cols-3">
        <div className="rounded-3xl border border-slate-200 bg-white p-6 shadow-sm">
          <h2 className="text-sm uppercase tracking-[0.2em] text-slate-400">Reports</h2>
          <p className="mt-4 text-3xl font-semibold text-maroon">{overview?.reportCount ?? '—'}</p>
        </div>
        <div className="rounded-3xl border border-slate-200 bg-white p-6 shadow-sm">
          <h2 className="text-sm uppercase tracking-[0.2em] text-slate-400">Emergencies</h2>
          <p className="mt-4 text-3xl font-semibold text-darkblue">{overview?.emergencyCount ?? '—'}</p>
        </div>
        <div className="rounded-3xl border border-slate-200 bg-white p-6 shadow-sm">
          <h2 className="text-sm uppercase tracking-[0.2em] text-slate-400">Recent logs</h2>
          <p className="mt-4 text-3xl font-semibold text-softgreen">{overview?.recentAudits?.length ?? '—'}</p>
        </div>
      </div>

      <section className="rounded-3xl border border-slate-200 bg-white p-6 shadow-sm">
        <h2 className="text-xl font-semibold text-darkblue">Report Trends</h2>
        <div className="mt-6 h-80">
          <ResponsiveContainer width="100%" height="100%">
            <BarChart data={trends}>
              <XAxis dataKey="_id" />
              <YAxis />
              <Tooltip />
              <Bar dataKey="count" fill="#7B1F3C" />
            </BarChart>
          </ResponsiveContainer>
        </div>
      </section>
    </div>
  );
}

export default DashboardPage;
