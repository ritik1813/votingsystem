from flask import Flask, render_template, request, jsonify, redirect, url_for
from flask_socketio import SocketIO
import json
import os
from datetime import datetime
import statistics
import traceback

app = Flask(__name__)
app.config['SECRET_KEY'] = 'hackathon_voting_secret_key'
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
    try:
        with open(VOTES_FILE, 'r') as f:
            return json.load(f)
    except Exception as e:
        print(f"Error loading votes: {e}")
        # Return default structure on error
        return {
            'team1': {'voteCount': 0, 'votes': []},
            'team2': {'voteCount': 0, 'votes': []},
            'team3': {'voteCount': 0, 'votes': []}
        }

def load_results():
    try:
        with open(RESULTS_FILE, 'r') as f:
            return json.load(f)
    except Exception as e:
        print(f"Error loading results: {e}")
        # Return default structure on error
        return {
            'presentationAward': {'teams': []},
            'implementationAward': {'teams': []}
        }

# Save data
def save_votes(votes_data):
    try:
        with open(VOTES_FILE, 'w') as f:
            json.dump(votes_data, f)
        return True
    except Exception as e:
        print(f"Error saving votes: {e}")
        return False

def save_results(results_data):
    try:
        with open(RESULTS_FILE, 'w') as f:
            json.dump(results_data, f)
        return True
    except Exception as e:
        print(f"Error saving results: {e}")
        return False

# Calculate results from votes
def calculate_results():
    try:
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
            if not team_data.get('votes', []):
                continue
                
            # Process presentation scores
            presentation_scores = {}
            for vote in team_data.get('votes', []):
                if not isinstance(vote, dict):
                    print(f"Invalid vote format: {vote}")
                    continue
                    
                for subcat, score in vote.get('presentationSkills', {}).items():
                    if subcat not in presentation_scores:
                        presentation_scores[subcat] = []
                    presentation_scores[subcat].append(score)
            
            # Calculate average scores for presentation
            presentation_avg_scores = {}
            for subcat, scores in presentation_scores.items():
                if scores:
                    try:
                        presentation_avg_scores[subcat] = statistics.mean(scores)
                    except Exception as e:
                        print(f"Error calculating mean for {subcat}: {e}, scores: {scores}")
                        presentation_avg_scores[subcat] = 0
            
            if presentation_avg_scores:
                try:
                    presentation_average = statistics.mean(list(presentation_avg_scores.values()))
                except Exception as e:
                    print(f"Error calculating presentation average: {e}")
                    presentation_average = 0
                    
                results['presentationAward']['teams'].append({
                    'id': int(team_id.replace('team', '')),
                    'name': team_names.get(team_id, f'Team {team_id}'),
                    'members': team_members.get(team_id, []),
                    'comment': team_comments.get(team_id, ''),
                    'scores': presentation_avg_scores,
                    'average': presentation_average,
                    'votes': len(team_data.get('votes', []))
                })
            
            # Process implementation scores
            implementation_scores = {}
            for vote in team_data.get('votes', []):
                if not isinstance(vote, dict):
                    continue
                    
                for subcat, score in vote.get('implementationQuality', {}).items():
                    if subcat not in implementation_scores:
                        implementation_scores[subcat] = []
                    implementation_scores[subcat].append(score)
            
            # Calculate average scores for implementation
            implementation_avg_scores = {}
            for subcat, scores in implementation_scores.items():
                if scores:
                    try:
                        implementation_avg_scores[subcat] = statistics.mean(scores)
                    except Exception as e:
                        print(f"Error calculating mean for {subcat}: {e}, scores: {scores}")
                        implementation_avg_scores[subcat] = 0
            
            if implementation_avg_scores:
                try:
                    implementation_average = statistics.mean(list(implementation_avg_scores.values()))
                except Exception as e:
                    print(f"Error calculating implementation average: {e}")
                    implementation_average = 0
                    
                results['implementationAward']['teams'].append({
                    'id': int(team_id.replace('team', '')),
                    'name': team_names.get(team_id, f'Team {team_id}'),
                    'members': team_members.get(team_id, []),
                    'comment': team_comments.get(team_id, ''),
                    'scores': implementation_avg_scores,
                    'average': implementation_average,
                    'votes': len(team_data.get('votes', []))
                })
        
        # Sort teams by average score
        results['presentationAward']['teams'].sort(key=lambda x: x.get('average', 0), reverse=True)
        results['implementationAward']['teams'].sort(key=lambda x: x.get('average', 0), reverse=True)
        
        save_results(results)
        return results
    except Exception as e:
        print(f"Error calculating results: {e}")
        print(traceback.format_exc())
        return {
            'presentationAward': {'teams': []},
            'implementationAward': {'teams': []}
        }

# Routes
@app.route('/')
def index():
    return render_template('index.html')

# Route for results page
@app.route('/results')
def results_page():
    return render_template('index.html')

@app.route('/api/voting-status')
def voting_status():
    votes_data = load_votes()
    results_data = load_results()
    
    # Calculate vote counts only
    for team_id, team_data in votes_data.items():
        votes_data[team_id]['voteCount'] = len(team_data.get('votes', []))
    
    return jsonify({
        'votes': votes_data,
        'results': results_data
    })

@app.route('/api/submit-votes', methods=['POST'])
def submit_votes():
    try:
        # Get and validate request data
        if not request.is_json:
            return jsonify({'status': 'error', 'message': 'Expected JSON data'}), 400
            
        vote_data = request.json
        print(f"Received vote data: {vote_data}")
        
        if not isinstance(vote_data, dict):
            return jsonify({'status': 'error', 'message': 'Invalid data format'}), 400
        
        # Load current votes
        votes = load_votes()
        
        # Process each team's votes
        for team_id, team_vote in vote_data.items():
            # Validate team_id format
            if not team_id.startswith('team'):
                print(f"Invalid team ID: {team_id}")
                continue
                
            # Ensure team exists in votes data
            if team_id not in votes:
                votes[team_id] = {'voteCount': 0, 'votes': []}
            
            # Validate team_vote structure
            if not isinstance(team_vote, dict):
                print(f"Invalid team vote format for {team_id}: {team_vote}")
                continue
                
            # Add the vote
            if 'votes' not in votes[team_id]:
                votes[team_id]['votes'] = []
                
            votes[team_id]['votes'].append(team_vote)
            votes[team_id]['voteCount'] = len(votes[team_id]['votes'])
        
        # Save updated votes
        save_success = save_votes(votes)
        if not save_success:
            return jsonify({'status': 'error', 'message': 'Failed to save votes'}), 500
        
        # Calculate and save results
        results = calculate_results()
        
        # Broadcast updates to all clients
        try:
            socketio.emit('voting_update', {'votes': votes})
            socketio.emit('results_update', {'results': results})
        except Exception as e:
            print(f"Socket emission error: {e}")
        
        return jsonify({'status': 'success'})
    except Exception as e:
        print(f"Error in submit_votes: {e}")
        print(traceback.format_exc())
        return jsonify({'status': 'error', 'message': str(e)}), 500

@app.route('/api/reset-votes', methods=['POST'])
def reset_votes():
    try:
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
    except Exception as e:
        print(f"Error in reset_votes: {e}")
        print(traceback.format_exc())
        return jsonify({'status': 'error', 'message': str(e)}), 500

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