import { useEffect, useState } from 'react';
import { fetchReports } from '../lib/api';

type ReportItem = {
  id: string;
  type: string;
  riskLevel: string;
  createdAt: string;
  description: string;
};

function normalizeReports(rawData: unknown): ReportItem[] {
  if (!Array.isArray(rawData)) {
    return [];
  }

  return rawData.map((item: any, index: number) => ({
    id: item?._id || `report-${index}`,
    type: typeof item?.type === 'string' ? item.type : 'Report',
    riskLevel: typeof item?.riskLevel === 'string' ? item.riskLevel : 'unknown',
    createdAt: typeof item?.createdAt === 'string' ? item.createdAt : '',
    description: typeof item?.description === 'string' && item.description.trim().length > 0 ? item.description : 'No description provided.'
  }));
}

function formatTimestamp(value: string) {
  if (!value) {
    return 'Unknown timestamp';
  }

  const parsed = new Date(value);
  if (Number.isNaN(parsed.getTime())) {
    return 'Unknown timestamp';
  }

  return parsed.toLocaleString();
}

function ReportsPage() {
  const [reports, setReports] = useState<ReportItem[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let isActive = true;

    const loadReports = async () => {
      setIsLoading(true);
      setError(null);

      try {
        const data = await fetchReports();
        if (!isActive) {
          return;
        }

        setReports(normalizeReports(data));
      } catch {
        if (isActive) {
          setError('Unable to load reports right now.');
        }
      } finally {
        if (isActive) {
          setIsLoading(false);
        }
      }
    };

    loadReports();

    return () => {
      isActive = false;
    };
  }, []);

  return (
    <div className="space-y-6">
      <h1 className="text-3xl font-bold text-darkblue">Report Management</h1>

      {error ? (
        <div className="rounded-2xl border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-800">
          {error}
        </div>
      ) : null}

      {isLoading ? (
        <div className="grid gap-4">
          {[1, 2, 3].map((item) => (
            <div key={item} className="rounded-3xl border border-slate-200 bg-white p-6 shadow-sm">
              <div className="h-4 w-36 animate-pulse rounded-full bg-slate-200" />
              <div className="mt-4 h-3 w-48 animate-pulse rounded bg-slate-200" />
            </div>
          ))}
        </div>
      ) : reports.length > 0 ? (
        <div className="grid gap-4">
          {reports.map((report) => (
            <div key={report.id} className="rounded-3xl border border-slate-200 bg-white p-6 shadow-sm">
              <div className="flex items-center justify-between gap-4">
                <div>
                  <h2 className="text-xl font-semibold text-maroon">{report.type}</h2>
                  <p className="text-slate-500">Risk: {report.riskLevel}</p>
                </div>
                <div className="text-sm text-slate-400">{formatTimestamp(report.createdAt)}</div>
              </div>
              <p className="mt-4 text-slate-600">{report.description}</p>
            </div>
          ))}
        </div>
      ) : (
        <div className="rounded-2xl border border-dashed border-slate-200 px-4 py-10 text-center text-slate-500">
          No live reports available.
        </div>
      )}
    </div>
  );
}

export default ReportsPage;
