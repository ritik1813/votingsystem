EOF

# Create index.html
echo "Creating index.html..."
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
    <script src="https://cdn.socket.io/4.4.1/socket.io.min.js"></script>
    <script src="https://unpkg.com/lucide-react@latest/dist/umd/lucide-react.js"></script>
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
            from { opacity: 0; transform: translateY(20px); }
            to { opacity: 1; transform: translateY(0); }
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

# Create app.py
echo "Creating app.py..."
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

# Final setup instructions
echo "=== Installation Complete ==="
echo
echo "To start the Hackathon Voting System:"
echo
echo "1. Activate the conda environment:"
echo "   conda activate hackathon-voting-system"
echo
echo "2. Start the Flask application:"
echo "   python app.py"
echo
echo "3. Open your browser and go to:"
echo "   http://localhost:5000"
echo
echo "Admin password for results view: admin123"
echo
echo "Enjoy your hackathon!"

# Make the script executable
chmod +x install.sh
#!/bin/bash

# Hackathon Voting System Installation Script
echo "=== Hackathon Voting System Installation ==="
echo "This script will set up the complete hackathon voting system."

# Check if conda is available
if ! command -v conda &> /dev/null; then
    echo "Conda is required but not installed. Please install Anaconda or Miniconda first."
    exit 1
fi

# Create project directory
mkdir -p hackathon-voting-system
cd hackathon-voting-system

# Create required directories
mkdir -p data static templates

# Create conda environment
echo "Creating conda environment..."
conda create -y -n hackathon-voting-system python=3.9
eval "$(conda shell.bash hook)"
conda activate hackathon-voting-system

# Install required packages
echo "Installing required packages..."
pip install flask flask-socketio python-socketio eventlet

# Create App.js
echo "Creating App.js..."
cat > static/App.js << 'EOF'
// App.js
// Main application component
  
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

  const renderWinner = () => {
    if (!overallWinner) {
      return (
        <div className="fixed inset-0 bg-black bg-opacity-90 z-50 flex items-center justify-center">
          <div className="bg-white p-8 rounded-lg text-center">
            <p className="text-xl">結果はまだ集計中です。しばらくお待ちください。</p>
            <button 
              onClick={() => {
                setShowWinner(false);
                setWinnerRevealed(false);
                setShowConfetti(false);
                setCurrentView('overview');
              }}
              className="mt-4 px-6 py-2 bg-gray-700 hover:bg-gray-600 text-white rounded-lg transition-colors"
            >
              戻る
            </button>
          </div>
        </div>
      );
    }
    
    return (
      <div className="fixed inset-0 bg-black bg-opacity-90 z-50 flex items-center justify-center">
        <div 
          className={`transform transition-all duration-1000 ${
            winnerRevealed ? 'scale-100 opacity-100' : 'scale-90 opacity-0'
          }`}
        >
          <div className="relative w-full max-w-xl mx-auto">
            <div className="bg-gradient-to-br from-gray-900 to-gray-800 rounded-2xl overflow-hidden shadow-2xl">
              <div className="relative overflow-hidden">
                {/* Top curved decoration */}
                <div className="absolute -top-40 -left-20 w-[120%] h-80 bg-gradient-to-br from-amber-400 via-amber-500 to-amber-600 rounded-full opacity-50 blur-md"></div>
                
                {/* Animated stars */}
                <div className="absolute inset-0">
                  {Array.from({ length: 30 }).map((_, i) => {
                    const size = Math.random() * 4 + 2;
                    const opacity = Math.random() * 0.5 + 0.3;
                    const left = Math.random() * 100;
                    const top = Math.random() * 100;
                    
                    return (
                      <div 
                        key={i}
                        className="absolute bg-white rounded-full animate-pulse"
                        style={{
                          width: `${size}px`,
                          height: `${size}px`,
                          left: `${left}%`,
                          top: `${top}%`,
                          opacity: opacity,
                          animationDuration: `${Math.random() * 3 + 2}s`
                        }}
                      ></div>
                    );
                  })}
                </div>

                <div className="pt-10 px-6 text-center relative z-10">
                  <div className="animate-bounce inline-block mb-4">
                    <div className="w-20 h-20 bg-gradient-to-br from-amber-400 to-amber-600 rounded-full flex items-center justify-center shadow-lg">
                      <lucide.Trophy size={42} className="text-white" />
                    </div>
                  </div>
                  
                  <h2 className="text-3xl font-bold text-white mb-3">
                    総合優勝
                  </h2>
                  
                  <div>
                    <h3 className="text-4xl font-bold text-amber-400 mb-4 tracking-wide">
                      {overallWinner.name}
                    </h3>
                  </div>
                  
                  <div>
                    <div className="text-center py-4">
                      <div className="flex justify-center mb-6">
                        <div className="px-4 py-2 rounded-xl bg-gray-800 mx-2">
                          <p className="text-indigo-300 font-medium mb-1">プレゼン</p>
                          <p className="text-xl font-bold text-white">{overallWinner.presentationScore.toFixed(2)}</p>
                        </div>
                        <div className="px-4 py-2 rounded-xl bg-gray-800 mx-2">
                          <p className="text-purple-300 font-medium mb-1">実装</p>
                          <p className="text-xl font-bold text-white">{overallWinner.implementationScore.toFixed(2)}</p>
                        </div>
                        <div className="px-4 py-2 rounded-xl bg-gradient-to-r from-amber-500 to-amber-600 mx-2">
                          <p className="text-amber-100 font-medium mb-1">総合点</p>
                          <p className="text-xl font-bold text-white">{overallWinner.totalScore.toFixed(2)}</p>
                        </div>
                      </div>
                      
                      <div className="bg-gray-800 bg-opacity-50 rounded-xl p-4 mb-6 max-w-md mx-auto">
                        <h4 className="text-gray-300 font-medium mb-2">チームメンバー</h4>
                        <p className="text-white text-base">{overallWinner.members.join(" • ")}</p>
                      </div>
                      
                      {overallWinner.comment && (
                        <div>
                          <p className="text-gray-300 italic max-w-md mx-auto text-sm">{overallWinner.comment}</p>
                        </div>
                      )}
                    </div>
                  </div>
                </div>
                
                <div className="p-6 text-center">
                  <button 
                    onClick={() => {
                      setShowWinner(false);
                      setWinnerRevealed(false);
                      setShowConfetti(false);
                      setCurrentView('overview');
                    }}
                    className="px-6 py-2 bg-gray-700 hover:bg-gray-600 text-white rounded-lg transition-colors"
                  >
                    結果に戻る
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
        
        {/* Confetti animation */}
        <div className="fixed inset-0 pointer-events-none">
          {Array.from({ length: 80 }).map((_, i) => {
            const size = Math.random() * 8 + 4;
            const colors = [
              'bg-amber-500', 'bg-indigo-500', 'bg-purple-500', 
              'bg-pink-500', 'bg-blue-500', 'bg-red-500', 
              'bg-green-500', 'bg-yellow-500'
            ];
            const color = colors[Math.floor(Math.random() * colors.length)];
            const left = Math.random() * 100;
            const delay = Math.random() * 2;
            
            return (
              <div 
                key={i}
                className={`absolute ${color} rounded-md animate-fall`}
                style={{
                  left: `${left}%`,
                  top: '-20px',
                  width: `${size}px`,
                  height: `${size}px`,
                  animationDelay: `${delay}s`,
                  animationDuration: `${Math.random() * 3 + 2}s`
                }}
              ></div>
            );
          })}
        </div>
      </div>
    );
  };

  return (
    <div className="max-w-3xl mx-auto p-4 bg-gradient-to-br from-gray-50 to-gray-100 rounded-xl shadow-xl font-sans">
      <style jsx>{`
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
      `}</style>
      
      <header className="text-center mb-6">
        <h1 className="text-2xl font-bold text-gray-800 mb-1">IIT 研修：ハッカソン最終報告会</h1>
        <p className="text-gray-600">2025/5/16</p>
      </header>
      
      <div className="bg-white p-4 rounded-xl shadow-lg relative overflow-hidden">
        {/* Decorative background element */}
        <div className="absolute top-0 right-0 w-48 h-48 bg-gradient-to-br from-indigo-50 to-purple-50 rounded-full -mr-24 -mt-24 opacity-70"></div>
        <div className="absolute bottom-0 left-0 w-48 h-48 bg-gradient-to-tr from-amber-50 to-yellow-50 rounded-full -ml-24 -mb-24 opacity-70"></div>
        
        <div className="relative z-10">
          {currentView === 'overview' && renderOverview()}
          
          {currentView === 'presentation' && renderDetailedResults(
            'presentation',
            rankedPresentationTeams,
            'プレゼン力賞',
            'プレゼンテーションスキル、発表内容、表現力を評価',
            'from-indigo-600 via-blue-600 to-indigo-700'
          )}
          
          {currentView === 'implementation' && renderDetailedResults(
            'implementation',
            rankedImplementationTeams,
            '実装力賞',
            '技術的完成度、使いやすさ、実用性、運用への貢献度を評価',
            'from-purple-600 via-fuchsia-600 to-purple-700'
          )}
        </div>
      </div>
      
      {showWinner && renderWinner()}
    </div>
  );
};
EOF

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

  const renderDetailedResults = (category, teams, title, subtitle, gradientColors) => {
    if (teams.length === 0) {
      return (
        <div className="text-center py-8">
          <p className="text-gray-600">結果はまだありません。投票が完了するのを待ってください。</p>
          <button 
            onClick={() => setCurrentView('overview')}
            className="mt-4 px-4 py-2 bg-gray-200 hover:bg-gray-300 rounded-lg inline-flex items-center transition-all hover:translate-x-1"
          >
            <lucide.ChevronRight className="rotate-180 mr-1" size={16} /> 戻る
          </button>
        </div>
      );
    }
    
    return (
      <div>
        <button 
          onClick={() => setCurrentView('overview')}
          className="mb-6 px-4 py-2 bg-gray-200 hover:bg-gray-300 rounded-lg inline-flex items-center transition-all hover:translate-x-1"
        >
          <lucide.ChevronRight className="rotate-180 mr-1" size={16} /> 戻る
        </button>
        
        <h2 className={`text-3xl font-bold mb-2 bg-gradient-to-r ${gradientColors} bg-clip-text text-transparent`}>
          {title}
        </h2>
        <p className="text-gray-600 mb-8">{subtitle}</p>
        
        <div className="space-y-8">
          {teams.map((team) => (
            <div 
              key={team.id}
              className={`rounded-xl shadow-lg overflow-hidden transform transition-all duration-500 ${
                team.rank === 1 
                  ? 'border-2 border-amber-400 scale-105' 
                  : 'border border-gray-200'
              } ${animateResults ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-10'}`}
              style={{ transitionDelay: `${team.rank * 200}ms` }}
            >
              <div className={`p-4 ${
                team.rank === 1 
                  ? 'bg-gradient-to-r from-amber-400 to-amber-300' 
                  : team.rank === 2 
                    ? 'bg-gradient-to-r from-gray-300 to-gray-200' 
                    : team.rank === 3 
                      ? 'bg-gradient-to-r from-amber-700 to-amber-600' 
                      : 'bg-gray-100'
              }`}>
                <div className="flex justify-between items-center">
                  <div className="flex items-center">
                    {team.rank === 1 && (
                      <div className="w-8 h-8 bg-amber-100 rounded-full flex items-center justify-center mr-2">
                        <lucide.Crown size={20} className="text-amber-600" />
                      </div>
                    )}
                    <h3 className="text-xl font-bold">
                      {team.rank === 1 ? '1位:' : team.rank === 2 ? '2位:' : '3位:'} {team.name}
                    </h3>
                  </div>
                  <div className="text-right">
                    <div className="text-sm font-medium">
                      スコア: <span className="font-bold text-lg">{team.average.toFixed(2)}</span>
                    </div>
                    <div className="text-xs text-gray-600">({team.votes} 票)</div>
                  </div>
                </div>
              </div>
              
              <div className="p-4 bg-white">
                <div className="flex items-start mb-4">
                  <lucide.Users size={18} className="text-gray-500 mt-0.5 mr-2 flex-shrink-0" />
                  <div>
                    <h4 className="font-medium text-gray-800 mb-1">チームメンバー</h4>
                    <p className="text-gray-600">{team.members.join(", ")}</p>
                  </div>
                </div>
                
                <div className="mb-4">
                  <h4 className="font-medium text-gray-800 mb-2">スコア詳細</h4>
                  <div className="grid grid-cols-2 gap-x-4 gap-y-3">
                    {Object.entries(team.scores).map(([key, value]) => (
                      <div key={key} className="flex justify-between items-center">
                        <span className="text-sm text-gray-600">
                          {key === 'pronunciation' ? '発音と明瞭さ' :
                           key === 'grammar' ? '文法の正確さ' :
                           key === 'structure' ? '構成力' :
                           key === 'slideQuality' ? 'スライドの質' :
                           key === 'expression' ? '表現力' :
                           key === 'requiredFeatures' ? '必須機能' :
                           key === 'scalability' ? '拡張性' :
                           key === 'usability' ? '使いやすさ' :
                           key === 'completeness' ? '完成度' :
                           key === 'technicalNovelty' ? '技術革新性' :
                           key === 'feasibility' ? '実現可能性' :
                           key === 'businessAppeal' ? 'ビジネス魅力' :
                           key === 'overallImpression' ? '総合印象' :
                           key}
                        </span>
                        <div className="flex items-center">
                          <div className="w-16 h-3 rounded-full overflow-hidden bg-gray-200 mr-2">
                            <div 
                              className={`h-full ${
                                team.rank === 1 
                                  ? 'bg-amber-500' 
                                  : team.rank === 2 
                                    ? 'bg-gray-500' 
                                    : team.rank === 3 
                                      ? 'bg-amber-700' 
                                      : category === 'presentation' 
                                        ? 'bg-indigo-500' 
                                        : 'bg-purple-500'
                              }`}
                              style={{
                                width: `${(value/5)*100}%`,
                                transition: 'width 1s ease-in-out'
                              }}
                            ></div>
                          </div>
                          <span className="font-medium">{value.toFixed(1)}</span>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
                
                {team.comment && (
                  <div>
                    <h4 className="font-medium text-gray-800 mb-1">チームコメント</h4>
                    <p className="text-gray-600 italic">{team.comment}</p>
                  </div>
                )}
              </div>
            </div>
          ))}
        </div>
      </div>
    );
  };
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

# Create VotingForm.js
echo "Creating VotingForm.js..."
cat > static/VotingForm.js << 'EOF'
// VotingForm.js
// No imports needed as we're using global React, etc.

const teams = [1, 2, 3];

const evaluationDescriptions = {
  presentationSkills: {
    pronunciation: {
      label: '発音・聞き取りやすさ',
      description: '発音・イントネーションが明瞭で、聞き取りやすい話し方になっているか'
    },
    grammar: {
      label: '文法の正確さ',
      description: '不自然な表現や誤用が少なく、日本語文法に沿って適切に話せているか'
    },
    structure: {
      label: '話の流れ・構成力',
      description: '話の展開が論理的で整理されており、伝えたいポイントが明確になっているか'
    },
    slideQuality: {
      label: 'プレゼン資料の完成度',
      description: 'スライドが見やすく整っており、図表・テキスト・デザインに工夫があるか'
    },
    expression: {
      label: '表現の工夫・印象',
      description: '聞き手に伝わる表現・抑揚・感情の込め方など、印象に残るプレゼンになっているか'
    }
  },
  implementationQuality: {
    requiredFeatures: {
      label: '必須機能の実装度',
      description: '認証、位置情報、帳票出力などの必須機能が確実に動作するか'
    },
    scalability: {
      label: '拡張性',
      description: '今後の機能追加(例:休暇管理、給与連携)への対応がしやすい構造か'
    },
    usability: {
      label: '操作性・使用感',
      description: '誰でも直感的に操作できるデザインか(UI/UX)'
    },
    completeness: {
      label: '完成度',
      description: '全体的にエラーが少なく、安定して使える仕上がりになっているか'
    },
    technicalNovelty: {
      label: '技術の新規性・独自性',
      description: '既存の勤怠アプリにはない仕組み・発想が取り入れられているか'
    },
    feasibility: {
      label: '実現可能性',
      description: '現実の業務にそのまま導入できるか、現実性があるか'
    },
    businessAppeal: {
      label: '営業的な魅力',
      description: '顧客にとっての導入価値が明確で、「欲しい」と思わせる内容か'
    },
    overallImpression: {
      label: '総合的印象(人気投票)',
      description: '実際に試した来場者が「一番良い」と感じたかどうか(ライト評価)'
    }
  }
};

const VotingForm = () => {
  const [currentTeam, setCurrentTeam] = React.useState(1);
  const [submitted, setSubmitted] = React.useState(false);
  const [formData, setFormData] = React.useState(() => {
    const init = {};
    teams.forEach((t) => {
      init[`team${t}`] = {
        presentationSkills: Object.fromEntries(Object.keys(evaluationDescriptions.presentationSkills).map(k => [k, 0])),
        implementationQuality: Object.fromEntries(Object.keys(evaluationDescriptions.implementationQuality).map(k => [k, 0]))
      };
    });
    return init;
  });

  const handleRating = (team, cat, subcat, rating) => {
    setFormData(prev => ({
      ...prev,
      [`team${team}`]: {
        ...prev[`team${team}`],
        [cat]: {
          ...prev[`team${team}`][cat],
          [subcat]: rating
        }
      }
    }));
  };

  const isTeamComplete = (team) => {
    const data = formData[`team${team}`];
    return Object.values(data.presentationSkills).every(val => val > 0) &&
      Object.values(data.implementationQuality).every(val => val > 0);
  };

  const renderStars = (team, cat, subcat) => (
    <div className="flex gap-2 mt-2">
      {[1, 2, 3, 4, 5].map(i => (
        <button
          key={i}
          className={`p-1 transition transform hover:scale-110 ${formData[`team${team}`][cat][subcat] === i ? 'text-yellow-500' : 'text-gray-300'}`}
          onClick={() => handleRating(team, cat, subcat, i)}
        >
          <lucide.Star fill={formData[`team${team}`][cat][subcat] >= i ? '#facc15' : 'none'} />
        </button>
      ))}
    </div>
  );
  
  const handleSubmit = () => {
    if (teams.every(isTeamComplete)) {
      // Send the data to the server
      fetch('/api/submit-votes', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(formData),
      })
      .then(response => response.json())
      .then(data => {
        console.log('Success:', data);
        setSubmitted(true);
      })
      .catch((error) => {
        console.error('Error:', error);
        // Handle error here
      });
    }
  };

  if (submitted) {
    return (
      <div className="text-center py-10 animate-fade-in">
        <div className="text-green-600 text-4xl mb-4"><lucide.Check size={48} /></div>
        <h2 className="text-2xl font-bold">ありがとうございました！</h2>
        <p className="text-gray-600">あなたの投票が正常に送信されました。</p>
      </div>
    );
  }

  return (
    <div className="max-w-5xl mx-auto px-6 py-10 bg-gradient-to-br from-sky-100 to-indigo-100 rounded-xl shadow-2xl">
      <h1 className="text-3xl font-bold text-center mb-8 text-indigo-800">🎓 ハッカソン 投票フォーム</h1>

      <div className="flex justify-center gap-6 mb-6">
        {teams.map((team) => (
          <button
            key={team}
            onClick={() => setCurrentTeam(team)}
            className={`px-5 py-2 rounded-full text-lg font-semibold transition shadow-md transform hover:scale-105 ${
              currentTeam === team ? 'bg-indigo-600 text-white' : isTeamComplete(team) ? 'bg-green-200 text-green-900' : 'bg-gray-200 text-gray-700'
            }`}
          >
            チーム {team}
          </button>
        ))}
      </div>

      <div
        key={currentTeam}
        className="bg-white p-6 rounded-lg shadow-md"
      >
        {Object.entries(evaluationDescriptions).map(([catKey, subcats]) => (
          <div key={catKey} className="mb-8">
            <h2 className="text-xl font-bold text-indigo-700 mb-4">
              {catKey === 'presentationSkills' ? '🎤 プレゼン力賞' : '💻 実装力賞'}
            </h2>
            {Object.entries(subcats).map(([key, { label, description }]) => (
              <div key={key} className="mb-4">
                <div className="text-sm text-gray-700 font-medium">{label}</div>
                <div className="text-xs text-gray-500 italic">{description}</div>
                {renderStars(currentTeam, catKey, key)}
              </div>
            ))}
          </div>
        ))}

        <div className="flex justify-between mt-8">
          {currentTeam > 1 && (
            <button
              onClick={() => setCurrentTeam(currentTeam - 1)}
              className="px-4 py-2 rounded-lg bg-gray-300 hover:bg-gray-400 text-gray-800 shadow-md"
            >
              ← 前へ
            </button>
          )}
          {currentTeam < 3 ? (
            <button
              onClick={() => isTeamComplete(currentTeam) && setCurrentTeam(currentTeam + 1)}
              className={`px-6 py-2 rounded-lg shadow-md text-white ${isTeamComplete(currentTeam) ? 'bg-indigo-600 hover:bg-indigo-700' : 'bg-indigo-300 cursor-not-allowed'}`}
            >
              次へ →
            </button>
          ) : (
            <button
              onClick={handleSubmit}
              className={`px-6 py-2 rounded-lg shadow-md text-white ${teams.every(isTeamComplete) ? 'bg-green-600 hover:bg-green-700' : 'bg-green-300 cursor-not-allowed'}`}
            >
              送信 <lucide.Send className="inline ml-2" size={16} />
            </button>
          )}
        </div>

        {!isTeamComplete(currentTeam) && (
          <div className="mt-6 p-4 border border-yellow-300 bg-yellow-50 rounded-md text-yellow-800 flex items-center gap-2">
            <lucide.AlertCircle size={20} /> すべての項目を入力してください。
          </div>
        )}
      </div>
    </div>
  );
};
EOF

# Create ResultsDisplay.js
echo "Creating ResultsDisplay.js..."
cat > static/ResultsDisplay.js << 'EOF'
// ResultsDisplay.js
// No imports needed as we're using global React, etc.

const ResultsDisplay = () => {
  const [results, setResults] = React.useState({
    presentationAward: {
      teams: []
    },
    implementationAward: {
      teams: []
    }
  });

  const [currentView, setCurrentView] = React.useState('overview');
  const [showConfetti, setShowConfetti] = React.useState(false);
  const [animateResults, setAnimateResults] = React.useState(false);
  const [liveData, setLiveData] = React.useState(null);
  const [showWinner, setShowWinner] = React.useState(false);
  const [winnerRevealed, setWinnerRevealed] = React.useState(false);
  const [showResults, setShowResults] = React.useState(false);
  const audioRef = React.useRef(null);
  const socketRef = React.useRef(null);

  React.useEffect(() => {
    // Connect to the Socket.IO server
    socketRef.current = io();
    
    // Listen for live voting updates
    socketRef.current.on('voting_update', (data) => {
      setLiveData(data.votes);
    });
    
    // Listen for results updates
    socketRef.current.on('results_update', (data) => {
      setResults(data.results);
    });
    
    // Initialize audio for winner announcement
    audioRef.current = new Audio('https://assets.mixkit.co/active_storage/sfx/944/944-preview.mp3');
    
    // Fetch initial data
    fetch('/api/voting-status')
      .then(response => response.json())
      .then(data => {
        if (data.votes) {
          setLiveData(data.votes);
        }
        if (data.results) {
          setResults(data.results);
        }
      })
      .catch(error => console.error('Error fetching initial data:', error));
    
    return () => {
      // Disconnect socket when component unmounts
      if (socketRef.current) {
        socketRef.current.disconnect();
      }
    };
  }, []);

  React.useEffect(() => {
    if (currentView === 'overview') {
      setAnimateResults(false);
    } else {
      setTimeout(() => setAnimateResults(true), 500);
    }
  }, [currentView]);

  const showAwards = () => {
    setShowConfetti(true);
    setShowWinner(true);
    
    // Play sound effect when showing winner
    if (audioRef.current) {
      audioRef.current.play().catch(e => console.log("Audio playback prevented by browser", e));
    }
    
    // Animate winner reveal
    setTimeout(() => {
      setWinnerRevealed(true);
    }, 2000);
    
    // Notify server about award ceremony
    socketRef.current.emit('award_ceremony_started');
  };

  // Get ranked teams for both categories
  const getRankedTeams = (category) => {
    if (!results[category] || !results[category].teams || results[category].teams.length === 0) {
      return [];
    }
    
    // Sort teams by average score
    const sortedTeams = [...results[category].teams].sort((a, b) => b.average - a.average);
    
    // Add ranking
    return sortedTeams.map((team, index) => ({
      ...team,
      rank: index + 1
    }));
  };

  const rankedPresentationTeams = getRankedTeams('presentationAward');
  const rankedImplementationTeams = getRankedTeams('implementationAward');

  // Calculate overall winner (combines both presentation and implementation scores)
  const calculateOverallWinner = () => {
    if (rankedPresentationTeams.length === 0 || rankedImplementationTeams.length === 0) {
      return null;
    }
    
    const teamScores = {};
    
    // Initialize team scores with presentation scores
    rankedPresentationTeams.forEach(team => {
      teamScores[team.id] = {
        id: team.id,
        name: team.name,
        members: team.members,
        comment: team.comment,
        presentationScore: team.average,
        implementationScore: 0,
        totalScore: team.average * 0.5, // 50% weight for presentation
      };
    });
    
    // Add implementation scores
    rankedImplementationTeams.forEach(team => {
      if (teamScores[team.id]) {
        teamScores[team.id].implementationScore = team.average;
        teamScores[team.id].totalScore += team.average * 0.5; // 50% weight for implementation
      }
    });
    
    // Convert to array and sort
    const sortedTeams = Object.values(teamScores).sort((a, b) => b.totalScore - a.totalScore);
    
    return sortedTeams.length > 0 ? sortedTeams[0] : null; // Return the winner
  };

  const overallWinner = calculateOverallWinner();

  const renderOverview = () => (
    <div className="text-center">
      {liveData && (
        <div className="mb-10">
          <h3 className="text-2xl font-semibold mb-4 text-gray-800">ライブ投票状況</h3>
          <div className="flex justify-center gap-4">
            {Object.keys(liveData).map(teamId => {
              const teamNum = teamId.replace('team', '');
              const votes = liveData[teamId].voteCount || 0;
              
              return (
                <div key={teamId} className="bg-white rounded-xl shadow-md overflow-hidden border border-gray-200 w-28 transform hover:scale-105 transition-all duration-300">
                  <div className="bg-gradient-to-r from-gray-800 to-gray-900 text-white p-2 text-center">
                    <h4 className="font-bold text-lg">チーム {teamNum}</h4>
                  </div>
                  
                  <div className="p-3 text-center">
                    <div className="text-3xl font-bold text-gray-800">{votes}</div>
                    <div className="text-xs text-gray-500 mt-1">投票数</div>
                  </div>
                </div>
              );
            })}
          </div>
          
          <div className="mt-6 flex justify-center">
            <button
              onClick={() => setShowResults(!showResults)}
              className="flex items-center gap-2 px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg transition-all shadow"
            >
              {showResults ? (
                <>
                  <span>結果を隠す</span>
                  <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                    <path d="M6 9l6 6 6-6" />
                  </svg>
                </>
              ) : (
                <>
                  <span>結果を表示</span>
                  <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                    <path d="M18 15l-6-6-6 6" />
                  </svg>
                </>
              )}
            </button>
          </div>
        </div>
      )}
      
      {showResults && (
        <>
          <h2 className="text-3xl font-bold mb-8 bg-gradient-to-r from-indigo-600 via-purple-600 to-pink-600 bg-clip-text text-transparent">
            ハッカソン結果
          </h2>
          
          <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
            <button 
              onClick={() => setCurrentView('presentation')}
              className="p-8 rounded-xl bg-gradient-to-br from-indigo-500 to-indigo-700 text-white shadow-lg hover:shadow-xl transition-all transform hover:scale-105 duration-300 flex flex-col items-center justify-center relative overflow-hidden group"
            >
              <div className="absolute inset-0 bg-white opacity-0 group-hover:opacity-10 transition-opacity duration-300"></div>
              <div className="absolute -top-20 -right-20 w-40 h-40 bg-indigo-400 rounded-full opacity-20"></div>
              <lucide.Award size={60} className="mb-4 drop-shadow-lg" />
              <h3 className="text-xl font-bold mb-2">プレゼン力賞</h3>
              <p className="text-indigo-100">プレゼンテーションスキル</p>
            </button>
            
            <button 
              onClick={() => setCurrentView('implementation')}
              className="p-8 rounded-xl bg-gradient-to-br from-fuchsia-500 to-purple-700 text-white shadow-lg hover:shadow-xl transition-all transform hover:scale-105 duration-300 flex flex-col items-center justify-center relative overflow-hidden group"
            >
              <div className="absolute inset-0 bg-white opacity-0 group-hover:opacity-10 transition-opacity duration-300"></div>
              <div className="absolute -top-20 -right-20 w-40 h-40 bg-purple-400 rounded-full opacity-20"></div>
              <lucide.Code size={60} className="mb-4 drop-shadow-lg" />
              <h3 className="text-xl font-bold mb-2">実装力賞</h3>
              <p className="text-purple-100">実装の質</p>
            </button>
          </div>
          
          <button 
            onClick={showAwards}
            className="mt-12 px-8 py-4 bg-gradient-to-r from-amber-400 to-amber-600 hover:from-amber-500 hover:to-amber-700 text-white rounded-lg shadow-lg hover:shadow-xl flex items-center justify-center mx-auto transition-all transform hover:scale-105 duration-300 font-bold text-lg"
            disabled={!overallWinner}
          >
            <lucide.Trophy size={24} className="mr-3" /> 最終結果を発表
          </button>
        </>
      )}
    </div>
  );