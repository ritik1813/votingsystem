#!/bin/bash

# Hackathon Voting System Deployment Script
echo "===== Hackathon Voting System Deployment ====="

# Ensure script fails on error
set -e

# Check for required tools
echo "Checking system requirements..."
command -v python3 >/dev/null 2>&1 || { echo "Python 3 is required but not installed. Aborting."; exit 1; }
command -v conda >/dev/null 2>&1 || { echo "Conda is required but not installed. Aborting."; exit 1; }

# Create and activate conda environment
echo "Setting up conda environment..."
conda create -y -n hackathon-voting-system python=3.9
eval "$(conda shell.bash hook)"
conda activate hackathon-voting-system

# Install required packages
echo "Installing required packages..."
pip install flask flask-socketio python-socketio eventlet

# Create directory structure
echo "Setting up project directories..."
mkdir -p data static templates

# Convert JSX files to JS
echo "Converting React components to JS..."

# App.jsx to App.js
cat > static/App.js << 'EOF'
const App = () => {
  const [currentView, setCurrentView] = React.useState('voting'); // 'voting' or 'results'
  const [isAdmin, setIsAdmin] = React.useState(false);
  const [password, setPassword] = React.useState('');
  const [passwordError, setPasswordError] = React.useState('');

  const handleLogin = (e) => {
    e.preventDefault();
    // In a real app, you would validate this server-side
    if (password === 'admin123') {
      setIsAdmin(true);
      setPasswordError('');
    } else {
      setPasswordError('パスワードが正しくありません');
    }
  };

  if (currentView === 'voting') {
    return (
      <div className="min-h-screen bg-gray-100 py-8 px-4">
        <div className="max-w-7xl mx-auto">
          <div className="flex justify-between items-center mb-8">
            <h1 className="text-3xl font-bold text-gray-900">ハッカソン投票システム</h1>
            <button
              onClick={() => setCurrentView('results')}
              className="px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg shadow"
            >
              結果表示へ
            </button>
          </div>
          <VotingForm />
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-100 py-8 px-4">
      <div className="max-w-7xl mx-auto">
        <div className="flex justify-between items-center mb-8">
          <h1 className="text-3xl font-bold text-gray-900">ハッカソン結果表示</h1>
          <button
            onClick={() => setCurrentView('voting')}
            className="px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg shadow"
          >
            投票フォームへ
          </button>
        </div>

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
                />
              </div>
              <div className="flex items-center justify-center">
                <button
                  type="submit"
                  className="bg-indigo-600 hover:bg-indigo-700 text-white font-bold py-2 px-6 rounded focus:outline-none focus:shadow-outline"
                >
                  ログイン
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
EOF

# Create the app.py file
echo "Creating Flask application..."
cat > app.py << 'EOF'
from flask import Flask, render_template, request, jsonify
from flask_socketio import SocketIO
import json
import os
from datetime import datetime
import statistics

app = Flask(__name__)
app.config['SECRET_KEY'] = 'your_secret_key'
socketio = SocketIO(app, cors_allowed_origins="*")

# Data storage - in a real app, use a database
DATA_DIR = 'data'
VOTES_FILE = os.path.join(DATA_DIR, 'votes.json')
RESULTS_FILE = os.path.join(DATA_DIR, 'results.json')

# Ensure data directory exists
os.makedirs(DATA_DIR, exist_ok=True)

# Initialize data files if they don't exist
def initialize_data_files():
    if not os.path.exists(VOTES_FILE):
        with open(VOTES_FILE, 'w') as f:
            json.dump({
                'team1': {'voteCount': 0, 'votes': []},
                'team2': {'voteCount': 0, 'votes': []},
                'team3': {'voteCount': 0, 'votes': []}
            }, f)
    
    if not os.path.exists(RESULTS_FILE):
        with open(RESULTS_FILE, 'w') as f:
            json.dump({
                'presentationAward': {'teams': []},
                'implementationAward': {'teams': []}
            }, f)

initialize_data_files()

# Load data
def load_votes():
    with open(VOTES_FILE, 'r') as f:
        return json.load(f)

def load_results():
    with open(RESULTS_FILE, 'r') as f:
        return json.load(f)

# Save data
def save_votes(votes_data):
    with open(VOTES_FILE, 'w') as f:
        json.dump(votes_data, f)

def save_results(results_data):
    with open(RESULTS_FILE, 'w') as f:
        json.dump(results_data, f)

# Calculate results from votes
def calculate_results():
    votes_data = load_votes()
    results = {
        'presentationAward': {'teams': []},
        'implementationAward': {'teams': []}
    }
    
    team_names = {
        'team1': 'Team Alpha',
        'team2': 'Team Beta',
        'team3': 'Team Gamma'
    }
    
    team_members = {
        'team1': ['Tanaka Yuki', 'Suzuki Haruto', 'Sato Aoi'],
        'team2': ['Watanabe Hina', 'Ito Sota', 'Kobayashi Mei'],
        'team3': ['Yamamoto Ren', 'Nakamura Yuna', 'Kato Hiroto']
    }
    
    team_comments = {
        'team1': 'Our goal was to create an intuitive attendance system that simplifies daily check-ins.',
        'team2': 'We focused on creating a visually appealing interface with intuitive navigation.',
        'team3': 'Our solution integrates seamlessly with existing systems while providing new capabilities.'
    }
    
    for team_id, team_data in votes_data.items():
        if not team_data['votes']:
            continue
            
        # Process presentation scores
        presentation_scores = {}
        for vote in team_data['votes']:
            for subcat, score in vote.get('presentationSkills', {}).items():
                if subcat not in presentation_scores:
                    presentation_scores[subcat] = []
                presentation_scores[subcat].append(score)
        
        # Calculate average scores for presentation
        presentation_avg_scores = {}
        for subcat, scores in presentation_scores.items():
            if scores:
                presentation_avg_scores[subcat] = statistics.mean(scores)
        
        if presentation_avg_scores:
            presentation_average = statistics.mean(presentation_avg_scores.values())
            results['presentationAward']['teams'].append({
                'id': int(team_id.replace('team', '')),
                'name': team_names.get(team_id, f'Team {team_id}'),
                'members': team_members.get(team_id, []),
                'comment': team_comments.get(team_id, ''),
                'scores': presentation_avg_scores,
                'average': presentation_average,
                'votes': len(team_data['votes'])
            })
        
        # Process implementation scores
        implementation_scores = {}
        for vote in team_data['votes']:
            for subcat, score in vote.get('implementationQuality', {}).items():
                if subcat not in implementation_scores:
                    implementation_scores[subcat] = []
                implementation_scores[subcat].append(score)
        
        # Calculate average scores for implementation
        implementation_avg_scores = {}
        for subcat, scores in implementation_scores.items():
            if scores:
                implementation_avg_scores[subcat] = statistics.mean(scores)
        
        if implementation_avg_scores:
            implementation_average = statistics.mean(implementation_avg_scores.values())
            results['implementationAward']['teams'].append({
                'id': int(team_id.replace('team', '')),
                'name': team_names.get(team_id, f'Team {team_id}'),
                'members': team_members.get(team_id, []),
                'comment': team_comments.get(team_id, ''),
                'scores': implementation_avg_scores,
                'average': implementation_average,
                'votes': len(team_data['votes'])
            })
    
    # Sort teams by average score
    results['presentationAward']['teams'].sort(key=lambda x: x['average'], reverse=True)
    results['implementationAward']['teams'].sort(key=lambda x: x['average'], reverse=True)
    
    save_results(results)
    return results

# Routes
@app.route('/')
def index():
    return render_template('index.html')

@app.route('/api/voting-status')
def voting_status():
    votes_data = load_votes()
    results_data = load_results()
    
    # Calculate vote counts only
    for team_id, team_data in votes_data.items():
        votes_data[team_id]['voteCount'] = len(team_data['votes'])
    
    return jsonify({
        'votes': votes_data,
        'results': results_data
    })

@app.route('/api/submit-votes', methods=['POST'])
def submit_votes():
    vote_data = request.json
    votes = load_votes()
    
    # Process each team's votes
    for team_id, team_vote in vote_data.items():
        votes[team_id]['votes'].append(team_vote)
        votes[team_id]['voteCount'] = len(votes[team_id]['votes'])
    
    save_votes(votes)
    
    # Calculate and save results
    results = calculate_results()
    
    # Broadcast updates to all clients
    socketio.emit('voting_update', {'votes': votes})
    socketio.emit('results_update', {'results': results})
    
    return jsonify({'status': 'success'})

@app.route('/api/reset-votes', methods=['POST'])
def reset_votes():
    # Initialize fresh vote data
    votes_data = {
        'team1': {'voteCount': 0, 'votes': []},
        'team2': {'voteCount': 0, 'votes': []},
        'team3': {'voteCount': 0, 'votes': []}
    }
    
    # Initialize fresh results data
    results_data = {
        'presentationAward': {'teams': []},
        'implementationAward': {'teams': []}
    }
    
    save_votes(votes_data)
    save_results(results_data)
    
    # Broadcast updates to all clients
    socketio.emit('voting_update', {'votes': votes_data})
    socketio.emit('results_update', {'results': results_data})
    
    return jsonify({'status': 'success'})

# Socket.IO events
@socketio.on('connect')
def handle_connect():
    print('Client connected')

@socketio.on('disconnect')
def handle_disconnect():
    print('Client disconnected')

@socketio.on('award_ceremony_started')
def handle_award_ceremony():
    socketio.emit('award_ceremony', {'timestamp': datetime.now().isoformat()})

if __name__ == '__main__':
    socketio.run(app, debug=True)
EOF

# Create index.html
echo "Creating HTML template..."
cat > templates/index.html << 'EOF'
<!DOCTYPE html>
<html lang="ja">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ハッカソン投票システム</title>
    <link href="https://cdn.jsdelivr.net/npm/tailwindcss@2.2.19/dist/tailwind.min.css" rel="stylesheet">
    <script src="https://unpkg.com/react@17/umd/react.production.min.js"></script>
    <script src="https://unpkg.com/react-dom@17/umd/react-dom.production.min.js"></script>
    <script src="https://unpkg.com/@babel/standalone/babel.min.js"></script>
    <script src="https://unpkg.com/lucide-react@latest"></script>
    <script src="https://unpkg.com/framer-motion@latest"></script>
    <script src="https://cdn.socket.io/4.4.1/socket.io.min.js"></script>
    <style>
        @keyframes fall {
            0% { transform: translateY(0) rotate(0); opacity: 1; }
            100% { transform: translateY(600px) rotate(720deg); opacity: 0; }
        }
        
        .animate-fall {
            animation: fall ease-in forwards;
        }
        
        @keyframes pulse {
            0%, 100% { opacity: 0.4; }
            50% { opacity: 0.8; }
        }
        
        .animate-pulse {
            animation: pulse 2s ease-in-out infinite;
        }
        
        @keyframes bounce {
            0%, 100% { transform: translateY(0); }
            50% { transform: translateY(-15px); }
        }
        
        .animate-bounce {
            animation: bounce 2s ease-in-out infinite;
        }
        
        @keyframes fadeIn {
            from { opacity: 0; }
            to { opacity: 1; }
        }
        
        .animate-fade-in {
            animation: fadeIn 0.5s forwards;
        }
    </style>
</head>
<body class="bg-gray-100 min-h-screen">
    <div id="root"></div>
    
    <script type="text/babel" src="{{ url_for('static', filename='App.js') }}"></script>
    <script type="text/babel" src="{{ url_for('static', filename='VotingForm.js') }}"></script>
    <script type="text/babel" src="{{ url_for('static', filename='ResultsDisplay.js') }}"></script>
    <script type="text/babel">
        ReactDOM.render(<App />, document.getElementById('root'));
    </script>
</body>
</html>
EOF

# Start the Flask application
echo "===== Setup Complete! ====="
echo "To start the application, run:"
echo "conda activate hackathon-voting-system"
echo "python app.py"
echo ""
echo "Then, open your browser and navigate to: http://localhost:5000"
echo ""
echo "Admin access for results view:"
echo "- Password: admin123"