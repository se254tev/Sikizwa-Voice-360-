import { useEffect, useState } from 'react';
import { deleteReport, fetchAdminProfile, fetchReports, updateReportStatus } from '../lib/api';

type ReportItem = {
  id: string;
  type: string;
  reportType?: string;
  incidentType?: string;
  riskLevel: string;
  status: string;
  priority?: string;
  anonymousSubmission?: boolean;
  createdAt: string;
  description: string;
};

type AdminProfile = {
  role?: string;
};

function normalizeReports(rawData: unknown): ReportItem[] {
  if (!Array.isArray(rawData)) {
    return [];
  }

  return rawData.map((item: any, index: number) => ({
    id: item?._id || `report-${index}`,
    type: typeof item?.type === 'string' ? item.type : 'Report',
    reportType: typeof item?.reportType === 'string' ? item.reportType : undefined,
    incidentType: typeof item?.incidentType === 'string' ? item.incidentType : undefined,
    riskLevel: typeof item?.riskLevel === 'string' ? item.riskLevel : 'unknown',
    status: typeof item?.status === 'string' ? item.status : 'unknown',
    priority: typeof item?.priority === 'string' ? item.priority : undefined,
    anonymousSubmission: item?.anonymousSubmission === true,
    createdAt: typeof item?.createdAt === 'string' ? item.createdAt : '',
    description: typeof item?.description === 'string' && item.description.trim().length > 0 ? item.description : 'No description provided.',
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
  const [isActionLoading, setIsActionLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [actionError, setActionError] = useState<string | null>(null);
  const [adminRole, setAdminRole] = useState<string>('admin');

  const loadAdminProfile = async () => {
    try {
      const response = await fetchAdminProfile();
      if (response?.admin?.role) {
        setAdminRole(response.admin.role);
      }
    } catch {
      setAdminRole('admin');
    }
  };

  const loadReports = async () => {
    setIsLoading(true);
    setError(null);

    try {
      const data = await fetchReports();
      setReports(normalizeReports(data));
    } catch {
      setError('Unable to load reports right now.');
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    let isActive = true;

    Promise.all([loadAdminProfile(), loadReports()]).finally(() => {
      if (isActive) {
        setIsLoading(false);
      }
    });

    return () => {
      isActive = false;
    };
  }, []);

  const handleStatusChange = async (reportId: string, status: string) => {
    setActionError(null);
    setIsActionLoading(true);

    try {
      await updateReportStatus(reportId, status);
      await loadReports();
    } catch {
      setActionError('Unable to update report status. Please try again.');
    } finally {
      setIsActionLoading(false);
    }
  };

  const handleDelete = async (reportId: string) => {
    setActionError(null);
    setIsActionLoading(true);

    try {
      await deleteReport(reportId);
      await loadReports();
    } catch {
      setActionError('Unable to delete report. Please try again.');
    } finally {
      setIsActionLoading(false);
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-3xl font-bold text-darkblue">Report Management</h1>
          <p className="text-sm text-slate-500">View mobile-submitted reports, update statuses, and escalate cases safely.</p>
        </div>
        <div className="rounded-2xl bg-slate-100 px-4 py-3 text-sm text-slate-700">
          Role: <span className="font-semibold">{adminRole}</span>
        </div>
      </div>

      {error ? (
        <div className="rounded-2xl border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-800">
          {error}
        </div>
      ) : null}

      {actionError ? (
        <div className="rounded-2xl border border-rose-200 bg-rose-50 px-4 py-3 text-sm text-rose-800">
          {actionError}
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
              <div className="flex flex-col gap-4 md:flex-row md:items-start md:justify-between">
                <div>
                  <h2 className="text-xl font-semibold text-maroon">{report.incidentType || report.type}</h2>
                  <p className="text-slate-500">Type: {report.reportType || 'problem'}</p>
                  <p className="text-slate-500">Priority: {report.priority || 'medium'}</p>
                  <p className="text-slate-500">Status: {report.status}</p>
                </div>
                <div className="space-y-2 text-right text-sm text-slate-400">
                  <div>{formatTimestamp(report.createdAt)}</div>
                  <div>{report.anonymousSubmission ? 'Anonymous submission' : 'Identified user'}</div>
                </div>
              </div>

              <p className="mt-4 text-slate-600">{report.description}</p>

              <div className="mt-4 flex flex-wrap gap-3">
                {report.status !== 'resolved' ? (
                  <button
                    type="button"
                    onClick={() => handleStatusChange(report.id, 'resolved')}
                    disabled={isActionLoading}
                    className="rounded-2xl bg-emerald-600 px-4 py-2 text-sm font-semibold text-white hover:bg-emerald-700 disabled:opacity-60"
                  >
                    Mark Resolved
                  </button>
                ) : null}
                {report.status !== 'escalated' ? (
                  <button
                    type="button"
                    onClick={() => handleStatusChange(report.id, 'escalated')}
                    disabled={isActionLoading}
                    className="rounded-2xl bg-amber-600 px-4 py-2 text-sm font-semibold text-white hover:bg-amber-700 disabled:opacity-60"
                  >
                    Escalate
                  </button>
                ) : null}
                {report.status !== 'in-progress' ? (
                  <button
                    type="button"
                    onClick={() => handleStatusChange(report.id, 'in-progress')}
                    disabled={isActionLoading}
                    className="rounded-2xl bg-sky-600 px-4 py-2 text-sm font-semibold text-white hover:bg-sky-700 disabled:opacity-60"
                  >
                    Mark In Progress
                  </button>
                ) : null}
                {adminRole === 'super_admin' ? (
                  <button
                    type="button"
                    onClick={() => handleDelete(report.id)}
                    disabled={isActionLoading}
                    className="rounded-2xl bg-rose-600 px-4 py-2 text-sm font-semibold text-white hover:bg-rose-700 disabled:opacity-60"
                  >
                    Delete report
                  </button>
                ) : null}
              </div>
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
