import { useEffect, useState } from 'react';
import { fetchEmergencies } from '../lib/api';

type EmergencyItem = {
  id: string;
  severity: string;
  status: string;
  notes: string;
  createdAt: string;
};

function normalizeEmergencies(rawData: unknown): EmergencyItem[] {
  if (!Array.isArray(rawData)) {
    return [];
  }

  return rawData.map((item: any, index: number) => ({
    id: item?._id || `emergency-${index}`,
    severity: typeof item?.severity === 'string' && item.severity.length > 0 ? item.severity : 'unknown',
    status: typeof item?.status === 'string' && item.status.length > 0 ? item.status : 'pending',
    notes: typeof item?.notes === 'string' && item.notes.trim().length > 0 ? item.notes : 'No details provided.',
    createdAt: typeof item?.createdAt === 'string' ? item.createdAt : ''
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

function EmergenciesPage() {
  const [emergencies, setEmergencies] = useState<EmergencyItem[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let isActive = true;

    const loadEmergencies = async () => {
      setIsLoading(true);
      setError(null);

      try {
        const data = await fetchEmergencies();
        if (!isActive) {
          return;
        }

        setEmergencies(normalizeEmergencies(data));
      } catch {
        if (isActive) {
          setError('Unable to load emergency data right now.');
        }
      } finally {
        if (isActive) {
          setIsLoading(false);
        }
      }
    };

    loadEmergencies();

    return () => {
      isActive = false;
    };
  }, []);

  return (
    <div className="space-y-6">
      <h1 className="text-3xl font-bold text-darkblue">Emergency Monitoring</h1>

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
      ) : emergencies.length > 0 ? (
        <div className="grid gap-4">
          {emergencies.map((item) => (
            <div key={item.id} className="rounded-3xl border border-slate-200 bg-white p-6 shadow-sm">
              <div className="flex flex-wrap items-center justify-between gap-2">
                <h2 className="text-xl font-semibold text-maroon">{item.severity.toUpperCase()}</h2>
                <span className="rounded-full bg-cyan/10 px-3 py-1 text-sm text-cyan">{item.status}</span>
              </div>
              <p className="mt-3 text-slate-600">{item.notes}</p>
              <p className="mt-4 text-sm text-slate-500">Created: {formatTimestamp(item.createdAt)}</p>
            </div>
          ))}
        </div>
      ) : (
        <div className="rounded-2xl border border-dashed border-slate-200 px-4 py-10 text-center text-slate-500">
          No live emergency data available.
        </div>
      )}
    </div>
  );
}

export default EmergenciesPage;
