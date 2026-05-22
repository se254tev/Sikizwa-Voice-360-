import { useEffect, useState } from 'react';
import { fetchEmergencies } from '../lib/api';

function EmergenciesPage() {
  const [emergencies, setEmergencies] = useState<any[]>([]);

  useEffect(() => {
    fetchEmergencies().then(setEmergencies);
  }, []);

  return (
    <div className="space-y-6">
      <h1 className="text-3xl font-bold text-darkblue">Emergency Monitoring</h1>
      <div className="grid gap-4">
        {emergencies.map((item) => (
          <div key={item._id} className="rounded-3xl border border-slate-200 bg-white p-6 shadow-sm">
            <div className="flex flex-wrap items-center justify-between gap-2">
              <h2 className="text-xl font-semibold text-maroon">{item.severity.toUpperCase()}</h2>
              <span className="rounded-full bg-cyan/10 px-3 py-1 text-sm text-cyan">{item.status}</span>
            </div>
            <p className="mt-3 text-slate-600">{item.notes || 'No details provided.'}</p>
            <p className="mt-4 text-sm text-slate-500">Created: {new Date(item.createdAt).toLocaleString()}</p>
          </div>
        ))}
      </div>
    </div>
  );
}

export default EmergenciesPage;
