import { useEffect, useState } from 'react';
import { Routes, Route, Navigate, useNavigate } from 'react-router-dom';
import DashboardPage from './pages/Dashboard';
import ReportsPage from './pages/Reports';
import EmergenciesPage from './pages/Emergencies';
import CounsellorsPage from './pages/Counsellors';
import Sidebar from './components/Sidebar';
import LoginPage from './pages/Login';
import SignupPage from './pages/Signup';
import { adminLogout, fetchAdminProfile } from './lib/api';

function App() {
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [isReady, setIsReady] = useState(false);
  const [profileError, setProfileError] = useState('');
  const navigate = useNavigate();

  useEffect(() => {
    // Check authentication by attempting to fetch admin profile
    // Auth token is now stored in secure httpOnly cookie
    // If cookie exists, fetch will succeed; otherwise it fails
    fetchAdminProfile()
      .then(() => setIsAuthenticated(true))
      .catch(() => {
        setIsAuthenticated(false);
      })
      .finally(() => setIsReady(true));
  }, []);

  async function handleLogout() {
    try {
      await adminLogout();
    } finally {
      setIsAuthenticated(false);
      navigate('/login');
    }
  }

  if (!isReady) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-slate-50 text-slate-700">
        <div className="rounded-3xl border border-slate-200 bg-white px-8 py-10 shadow-lg">Checking session…</div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-slate-50 text-slate-900">
      <Routes>
        <Route
          path="/login"
          element={isAuthenticated ? <Navigate to="/" replace /> : <LoginPage />}
        />
        <Route
          path="/signup"
          element={isAuthenticated ? <Navigate to="/" replace /> : <SignupPage />}
        />
        <Route
          path="/*"
          element={
            isAuthenticated ? (
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
                    <div className="flex flex-col gap-3 lg:max-w-2xl lg:flex-row lg:items-center lg:justify-end">
                      <button
                        type="button"
                        onClick={handleLogout}
                        className="rounded-2xl border border-slate-200 bg-slate-50 px-4 py-2 text-sm font-semibold text-slate-800 hover:bg-slate-100"
                      >
                        Sign out
                      </button>
                    </div>
                  </div>

                  {profileError ? (
                    <div className="mb-6 rounded-2xl bg-rose-50 p-4 text-sm text-rose-700">{profileError}</div>
                  ) : null}

                  <Routes>
                    <Route path="/" element={<DashboardPage />} />
                    <Route path="/reports" element={<ReportsPage />} />
                    <Route path="/emergencies" element={<EmergenciesPage />} />
                    <Route path="/counsellors" element={<CounsellorsPage />} />
                    <Route path="*" element={<Navigate to="/" replace />} />
                  </Routes>
                </main>
              </div>
            ) : (
              <Navigate to="/login" replace />
            )
          }
        />
      </Routes>
    </div>
  );
}

export default App;
