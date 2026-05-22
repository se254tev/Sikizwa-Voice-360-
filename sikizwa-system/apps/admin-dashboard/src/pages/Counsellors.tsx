import { useEffect, useState } from 'react';
import { fetchCounsellors } from '../lib/api';

function CounsellorsPage() {
  const [counsellors, setCounsellors] = useState<any[]>([]);

  useEffect(() => {
    fetchCounsellors().then(setCounsellors);
  }, []);

  return (
    <div className="space-y-6">
      <h1 className="text-3xl font-bold text-darkblue">Counsellor Management</h1>
      <div className="grid gap-4">
        {counsellors.map((counsellor) => (
          <div key={counsellor._id} className="rounded-3xl border border-slate-200 bg-white p-6 shadow-sm">
            <div className="flex items-center justify-between gap-4">
              <div>
                <h2 className="text-xl font-semibold text-maroon">{counsellor.user?.username || 'Counsellor'}</h2>
                <p className="text-slate-500">{counsellor.specialties?.join(', ') || 'No specialties'}</p>
              </div>
              <div className="text-sm text-slate-400">Rating: {counsellor.rating?.toFixed(1) ?? '0.0'}</div>
            </div>
            <p className="mt-4 text-slate-600">Languages: {counsellor.languages?.join(', ') || 'N/A'}</p>
          </div>
        ))}
      </div>
    </div>
  );
}

export default CounsellorsPage;
