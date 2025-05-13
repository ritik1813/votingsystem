import React, { useState } from 'react';
import VotingForm from './components/VotingForm';
import ResultsDisplay from './components/ResultsDisplay';

// Create icon placeholders if needed
if (typeof window !== 'undefined' && !window.lucide) {
  window.lucide = {
    Award: (props) => React.createElement('div', { ...props, className: 'icon-placeholder' }, '🏆'),
    Trophy: (props) => React.createElement('div', { ...props, className: 'icon-placeholder' }, '🏆'),
    ChevronRight: (props) => React.createElement('div', { ...props, className: 'icon-placeholder' }, '→'),
    Users: (props) => React.createElement('div', { ...props, className: 'icon-placeholder' }, '👥'),
    Code: (props) => React.createElement('div', { ...props, className: 'icon-placeholder' }, '💻'),
    Star: (props) => React.createElement('div', { ...props, className: 'icon-placeholder' }, '★'),
    Crown: (props) => React.createElement('div', { ...props, className: 'icon-placeholder' }, '👑'),
    Check: (props) => React.createElement('div', { ...props, className: 'icon-placeholder' }, '✓'),
    Send: (props) => React.createElement('div', { ...props, className: 'icon-placeholder' }, '📤'),
    AlertCircle: (props) => React.createElement('div', { ...props, className: 'icon-placeholder' }, '⚠️')
  };
}

const App = () => {
  const isResultsPage = typeof window !== 'undefined' && window.location.pathname.includes('/results');
  const [isAdmin, setIsAdmin] = useState(false);
  const [password, setPassword] = useState('');
  const [passwordError, setPasswordError] = useState('');
  const [loading, setLoading] = useState(false);

  const handleLogin = (e) => {
    e.preventDefault();
    setLoading(true);

    setTimeout(() => {
      if (password === 'admin123') {
        setIsAdmin(true);
        setPasswordError('');
      } else {
        setPasswordError('パスワードが正しくありません');
      }
      setLoading(false);
    }, 500);
  };

  // Voting page
  if (!isResultsPage) {
    return (
      <div className="min-h-screen bg-gray-100 py-8 px-4">
        <div className="max-w-7xl mx-auto">
          <div className="flex justify-between items-center mb-8">
            <h1 className="text-3xl font-bold text-gray-900">ハッカソン投票システム</h1>
          </div>
          <VotingForm />
        </div>
      </div>
    );
  }

  // Results page
  return (
    <div className="min-h-screen bg-gray-100 py-8 px-4">
      <div className="max-w-7xl mx-auto">
        {!isAdmin ? (
          <div className="max-w-md mx-auto mt-16 bg-white p-8 rounded-lg shadow-lg">
            <h2 className="text-2xl font-bold mb-6 text-center">管理者ログイン</h2>
            {passwordError && (
              <div className="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-4">
                {passwordError}
              </div>
            )}
            <form onSubmit={handleLogin}>
              <div className="mb-4">
                <label className="block text-gray-700 text-sm font-bold mb-2" htmlFor="password">
                  パスワード
                </label>
                <input
                  type="password"
                  id="password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  className="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
                  placeholder="管理者パスワードを入力"
                  required
                  disabled={loading}
                />
              </div>
              <div className="flex items-center justify-center">
                <button
                  type="submit"
                  className={`bg-indigo-600 hover:bg-indigo-700 text-white font-bold py-2 px-6 rounded focus:outline-none focus:shadow-outline ${loading ? 'opacity-70 cursor-wait' : ''}`}
                  disabled={loading}
                >
                  {loading ? 'ログイン中...' : 'ログイン'}
                </button>
              </div>
            </form>
          </div>
        ) : (
          <ResultsDisplay />
        )}
      </div>
    </div>
  );
};

export default App;