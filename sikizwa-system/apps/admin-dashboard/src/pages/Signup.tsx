import { useState } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { adminSignup, saveAdminToken } from '../lib/api';

function SignupPage() {
  const navigate = useNavigate();
  const [fullName, setFullName] = useState('');
  const [phoneNumber, setPhoneNumber] = useState('');
  const [email, setEmail] = useState('');
  const [nationalId, setNationalId] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState('');

  async function handleSubmit(event) {
    event.preventDefault();
    setError('');

    if (!fullName.trim() || !phoneNumber.trim() || !email.trim() || !nationalId.trim() || !password || !confirmPassword) {
      setError('Please complete all required fields.');
      return;
    }

    if (password !== confirmPassword) {
      setError('Passwords do not match.');
      return;
    }

    setIsLoading(true);
    try {
      const response = await adminSignup({
        fullName: fullName.trim(),
        phoneNumber: phoneNumber.trim(),
        email: email.trim(),
        nationalId: nationalId.trim(),
        password,
        confirmPassword,
      });

      if (response && response.token) {
        saveAdminToken(response.token);
        navigate('/');
      } else {
        setError('Unable to create admin account.');
      }
    } catch (err) {
      setError(err?.message || 'Unable to create admin account.');
    } finally {
      setIsLoading(false);
    }
  }

  return (
    <div className="flex min-h-screen items-center justify-center bg-slate-50 px-4 py-12">
      <div className="w-full max-w-lg rounded-3xl border border-slate-200 bg-white p-8 shadow-lg">
        <div className="mb-8 text-center">
          <h1 className="text-3xl font-semibold text-darkblue">Admin Sign up</h1>
          <p className="mt-2 text-sm text-slate-500">Create a secure admin account for the Sikizwa dashboard.</p>
        </div>
        {error ? <div className="mb-4 rounded-xl bg-rose-50 p-3 text-sm text-rose-700">{error}</div> : null}
        <form onSubmit={handleSubmit} className="grid gap-4">
          <div className="grid gap-4 sm:grid-cols-2">
            <label className="block text-sm font-medium text-slate-700">
              Full name
              <input
                value={fullName}
                onChange={(event) => setFullName(event.target.value)}
                className="mt-2 w-full rounded-2xl border border-slate-300 bg-slate-50 px-4 py-3 text-sm outline-none focus:border-maroon focus:ring-2 focus:ring-maroon/10"
                placeholder="Jane Doe"
              />
            </label>
            <label className="block text-sm font-medium text-slate-700">
              Phone number
              <input
                value={phoneNumber}
                onChange={(event) => setPhoneNumber(event.target.value)}
                className="mt-2 w-full rounded-2xl border border-slate-300 bg-slate-50 px-4 py-3 text-sm outline-none focus:border-maroon focus:ring-2 focus:ring-maroon/10"
                placeholder="+254700000000"
              />
            </label>
          </div>

          <div className="grid gap-4 sm:grid-cols-2">
            <label className="block text-sm font-medium text-slate-700">
              Email address
              <input
                type="email"
                value={email}
                onChange={(event) => setEmail(event.target.value)}
                className="mt-2 w-full rounded-2xl border border-slate-300 bg-slate-50 px-4 py-3 text-sm outline-none focus:border-maroon focus:ring-2 focus:ring-maroon/10"
                placeholder="admin@example.com"
              />
            </label>
            <label className="block text-sm font-medium text-slate-700">
              National ID
              <input
                value={nationalId}
                onChange={(event) => setNationalId(event.target.value)}
                className="mt-2 w-full rounded-2xl border border-slate-300 bg-slate-50 px-4 py-3 text-sm outline-none focus:border-maroon focus:ring-2 focus:ring-maroon/10"
                placeholder="12345678"
              />
            </label>
          </div>

          <div className="grid gap-4 sm:grid-cols-2">
            <label className="block text-sm font-medium text-slate-700">
              Password
              <input
                type="password"
                value={password}
                onChange={(event) => setPassword(event.target.value)}
                className="mt-2 w-full rounded-2xl border border-slate-300 bg-slate-50 px-4 py-3 text-sm outline-none focus:border-maroon focus:ring-2 focus:ring-maroon/10"
                placeholder="Create a password"
              />
            </label>
            <label className="block text-sm font-medium text-slate-700">
              Confirm password
              <input
                type="password"
                value={confirmPassword}
                onChange={(event) => setConfirmPassword(event.target.value)}
                className="mt-2 w-full rounded-2xl border border-slate-300 bg-slate-50 px-4 py-3 text-sm outline-none focus:border-maroon focus:ring-2 focus:ring-maroon/10"
                placeholder="Repeat your password"
              />
            </label>
          </div>

          <button
            type="submit"
            disabled={isLoading}
            className="w-full rounded-2xl bg-maroon px-4 py-3 text-sm font-semibold text-white transition hover:bg-maroon/90 disabled:cursor-not-allowed disabled:opacity-60"
          >
            {isLoading ? 'Creating account…' : 'Create admin account'}
          </button>
        </form>
        <div className="mt-6 text-center text-sm text-slate-500">
          <span>Already have an admin account?</span>{' '}
          <Link to="/login" className="font-semibold text-maroon hover:text-maroon/80">
            Sign in
          </Link>
        </div>
      </div>
    </div>
  );
}

export default SignupPage;
