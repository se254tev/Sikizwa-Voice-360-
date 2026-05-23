import { Routes, Route } from 'react-router-dom';
import DashboardPage from './pages/Dashboard';
import ReportsPage from './pages/Reports';
import EmergenciesPage from './pages/Emergencies';
import CounsellorsPage from './pages/Counsellors';
import Sidebar from './components/Sidebar';

function App() {
  return (
    <div className="min-h-screen bg-slate-50 text-slate-900">
      <div className="flex min-h-screen flex-col lg:flex-row">
        <Sidebar />
        <main className="flex-1 p-4 sm:p-6">
          <div className="mb-6 flex flex-col gap-4 rounded-3xl border border-slate-200 bg-white p-4 shadow-sm lg:flex-row lg:items-center lg:justify-between">
            <div className="flex items-center gap-3">
              <div className="flex h-10 w-10 items-center justify-center rounded-full bg-maroon/10 text-maroon">
                <span className="text-lg font-semibold">AO</span>
              </div>
              <div>
                <p className="text-sm font-semibold text-darkblue">Admin workspace</p>
                <p className="text-sm text-slate-500">Realtime safety and wellness control.</p>
              </div>
            </div>

            <div className="flex flex-1 flex-col gap-3 lg:max-w-2xl lg:flex-row lg:items-center lg:justify-end">
              <label className="flex flex-1 items-center gap-2 rounded-full border border-slate-200 bg-slate-50 px-4 py-2 text-sm text-slate-500">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" className="h-4 w-4">
                  <circle cx="11" cy="11" r="6" />
                  <path d="m20 20-4.35-4.35" />
                </svg>
                <input
                  type="search"
                  placeholder="Search dashboard"
                  className="w-full border-0 bg-transparent outline-none placeholder:text-slate-400"
                />
              </label>

              <button
                type="button"
                aria-label="Notifications"
                className="flex h-10 w-10 items-center justify-center rounded-full bg-slate-100 text-slate-700"
              >
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" className="h-5 w-5">
                  <path d="M15 17h5l-1.4-1.4A2 2 0 0 1 18 14.2V11a6 6 0 1 0-12 0v3.2c0 .5-.2 1-.6 1.4L4 17h5" />
                  <path d="M10 19a2 2 0 0 0 4 0" />
                </svg>
              </button>

              <div className="flex items-center gap-3 rounded-full bg-slate-50 px-3 py-2">
                <div className="flex h-10 w-10 items-center justify-center rounded-full bg-maroon text-white">
                  <span className="text-sm font-semibold">AO</span>
                </div>
                <div>
                  <p className="text-sm font-semibold text-darkblue">Admin Officer</p>
                  <p className="text-xs text-slate-500">Moderator</p>
                </div>
              </div>
            </div>
          </div>

          <Routes>
            <Route path="/" element={<DashboardPage />} />
            <Route path="/reports" element={<ReportsPage />} />
            <Route path="/emergencies" element={<EmergenciesPage />} />
            <Route path="/counsellors" element={<CounsellorsPage />} />
          </Routes>
        </main>
      </div>
    </div>
  );
}

export default App;
