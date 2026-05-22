import { Link, useLocation } from 'react-router-dom';

const navItems = [
  { label: 'Dashboard', to: '/' },
  { label: 'Reports', to: '/reports' },
  { label: 'Emergencies', to: '/emergencies' },
  { label: 'Counsellors', to: '/counsellors' }
];

function Sidebar() {
  const location = useLocation();
  return (
    <aside className="w-72 border-r border-slate-200 bg-white p-6 shadow-sm">
      <div className="mb-10">
        <div className="text-2xl font-semibold text-maroon">Sikizwa Admin</div>
        <p className="text-sm text-slate-500 mt-1">Realtime safety and wellness control.</p>
      </div>
      <nav className="space-y-2">
        {navItems.map((item) => (
          <Link
            key={item.to}
            to={item.to}
            className={`block rounded-lg px-4 py-3 text-sm font-medium ${
              location.pathname === item.to ? 'bg-maroon text-white' : 'text-slate-700 hover:bg-slate-100'
            }`}
          >
            {item.label}
          </Link>
        ))}
      </nav>
    </aside>
  );
}

export default Sidebar;
