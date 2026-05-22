import { Routes, Route } from 'react-router-dom';
import DashboardPage from './pages/Dashboard';
import ReportsPage from './pages/Reports';
import EmergenciesPage from './pages/Emergencies';
import CounsellorsPage from './pages/Counsellors';
import Sidebar from './components/Sidebar';

function App() {
  return (
    <div className="min-h-screen bg-slate-50 text-slate-900">
      <div className="flex">
        <Sidebar />
        <main className="flex-1 p-6">
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
