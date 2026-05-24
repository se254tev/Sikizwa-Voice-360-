import { useState } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { adminLogin, saveAdminToken } from '../lib/api';

function LoginPage() {
  const navigate = useNavigate();
  const [identifier, setIdentifier] = useState('');
  const [password, setPassword] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState('');

  async function handleSubmit(event) {
    event.preventDefault();
    setError('');

    if (!identifier.trim() || !password) {
      setError('Email or phone and password are required.');
      return;
    }

    setIsLoading(true);
    try {
      const response = await adminLogin(identifier.trim(), password);
      if (response && response.token) {
        saveAdminToken(response.token);
        navigate('/');
      } else {
        setError('Authentication failed. Please try again.');
      }
    } catch (err) {
      setError(err?.message || 'Unable to authenticate.');
    } finally {
      setIsLoading(false);
    }
  }

  return (
    <div className="flex min-h-screen items-center justify-center bg-slate-50 px-4 py-12">
      <div className="w-full max-w-md rounded-3xl border border-slate-200 bg-white p-8 shadow-lg">
        <div className="mb-8 text-center">
          <h1 className="text-3xl font-semibold text-darkblue">Admin Sign in</h1>
          <p className="mt-2 text-sm text-slate-500">Access the Sikizwa admin dashboard securely.</p>
        </div>
        {error ? <div className="mb-4 rounded-xl bg-rose-50 p-3 text-sm text-rose-700">{error}</div> : null}
        <form onSubmit={handleSubmit} className="space-y-4">
          <label className="block text-sm font-medium text-slate-700">
            Email or phone number
            <input
              value={identifier}
              onChange={(event) => setIdentifier(event.target.value)}
              className="mt-2 w-full rounded-2xl border border-slate-300 bg-slate-50 px-4 py-3 text-sm outline-none focus:border-maroon focus:ring-2 focus:ring-maroon/10"
              placeholder="you@example.com or +254700000000"
            />
          </label>
          <label className="block text-sm font-medium text-slate-700">
            Password
            <input
              value={password}
              onChange={(event) => setPassword(event.target.value)}
              type="password"
              className="mt-2 w-full rounded-2xl border border-slate-300 bg-slate-50 px-4 py-3 text-sm outline-none focus:border-maroon focus:ring-2 focus:ring-maroon/10"
              placeholder="Enter your password"
            />
          </label>
          <button
            type="submit"
            disabled={isLoading}
            className="w-full rounded-2xl bg-maroon px-4 py-3 text-sm font-semibold text-white transition hover:bg-maroon/90 disabled:cursor-not-allowed disabled:opacity-60"
          >
            {isLoading ? 'Signing in…' : 'Sign in'}
          </button>
        </form>
        <div className="mt-6 text-center text-sm text-slate-500">
          <span>Need an admin account?</span>{' '}
          <Link to="/signup" className="font-semibold text-maroon hover:text-maroon/80">
            Sign up
          </Link>
        </div>
      </div>
    </div>
  );
}

export default LoginPage;
