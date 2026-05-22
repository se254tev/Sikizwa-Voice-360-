import { useEffect, useState } from 'react';
import { fetchReports } from '../lib/api';

function ReportsPage() {
  const [reports, setReports] = useState<any[]>([]);

  useEffect(() => {
    fetchReports().then(setReports);
  }, []);

  return (
    <div className="space-y-6">
      <h1 className="text-3xl font-bold text-darkblue">Report Management</h1>
      <div className="grid gap-4">
        {reports.map((report) => (
          <div key={report._id} className="rounded-3xl border border-slate-200 bg-white p-6 shadow-sm">
            <div className="flex items-center justify-between gap-4">
              <div>
                <h2 className="text-xl font-semibold text-maroon">{report.type}</h2>
                <p className="text-slate-500">Risk: {report.riskLevel}</p>
              </div>
              <div className="text-sm text-slate-400">{new Date(report.createdAt).toLocaleString()}</div>
            </div>
            <p className="mt-4 text-slate-600">{report.description || 'No description provided.'}</p>
          </div>
        ))}
      </div>
    </div>
  );
}

export default ReportsPage;
