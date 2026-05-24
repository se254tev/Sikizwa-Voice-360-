import { useEffect, useState } from 'react';
import { fetchCounsellors } from '../lib/api';

type CounsellorItem = {
  id: string;
  name: string;
  specialties: string;
  languages: string;
  rating: string;
};

function normalizeCounsellors(rawData: unknown): CounsellorItem[] {
  if (!Array.isArray(rawData)) {
    return [];
  }

  return rawData.map((item: any, index: number) => ({
    id: item?._id || `counsellor-${index}`,
    name: typeof item?.user?.username === 'string' && item.user.username.trim().length > 0 ? item.user.username : 'Counsellor',
    specialties: Array.isArray(item?.specialties) && item.specialties.length > 0 ? item.specialties.join(', ') : 'No specialties',
    languages: Array.isArray(item?.languages) && item.languages.length > 0 ? item.languages.join(', ') : 'N/A',
    rating: Number.isFinite(Number(item?.rating)) ? Number(item.rating).toFixed(1) : '0.0'
  }));
}

function CounsellorsPage() {
  const [counsellors, setCounsellors] = useState<CounsellorItem[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let isActive = true;

    const loadCounsellors = async () => {
      setIsLoading(true);
      setError(null);

      try {
        const data = await fetchCounsellors();
        if (!isActive) {
          return;
        }

        setCounsellors(normalizeCounsellors(data));
      } catch {
        if (isActive) {
          setError('Unable to load counsellor data right now.');
        }
      } finally {
        if (isActive) {
          setIsLoading(false);
        }
      }
    };

    loadCounsellors();

    return () => {
      isActive = false;
    };
  }, []);

  return (
    <div className="space-y-6">
      <h1 className="text-3xl font-bold text-darkblue">Counsellor Management</h1>

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
      ) : counsellors.length > 0 ? (
        <div className="grid gap-4">
          {counsellors.map((counsellor) => (
            <div key={counsellor.id} className="rounded-3xl border border-slate-200 bg-white p-6 shadow-sm">
              <div className="flex items-center justify-between gap-4">
                <div>
                  <h2 className="text-xl font-semibold text-maroon">{counsellor.name}</h2>
                  <p className="text-slate-500">{counsellor.specialties}</p>
                </div>
                <div className="text-sm text-slate-400">Rating: {counsellor.rating}</div>
              </div>
              <p className="mt-4 text-slate-600">Languages: {counsellor.languages}</p>
            </div>
          ))}
        </div>
      ) : (
        <div className="rounded-2xl border border-dashed border-slate-200 px-4 py-10 text-center text-slate-500">
          No live counsellor data available.
        </div>
      )}
    </div>
  );
}

export default CounsellorsPage;
