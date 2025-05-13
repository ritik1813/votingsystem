import { readFileSync, writeFileSync } from 'fs';
import path from 'path';

// Helper functions
const loadData = (file) => {
  try {
    const filePath = path.join(process.cwd(), 'data', file);
    const data = readFileSync(filePath, 'utf8');
    return JSON.parse(data);
  } catch (error) {
    console.error(`Error loading ${file}:`, error);
    
    // Return default data structure on error
    if (file === 'votes.json') {
      return {
        'team1': { 'voteCount': 0, 'votes': [] },
        'team2': { 'voteCount': 0, 'votes': [] },
        'team3': { 'voteCount': 0, 'votes': [] }
      };
    } else {
      return {
        'presentationAward': { 'teams': [] },
        'implementationAward': { 'teams': [] }
      };
    }
  }
};

const saveData = (file, data) => {
  try {
    const filePath = path.join(process.cwd(), 'data', file);
    writeFileSync(filePath, JSON.stringify(data, null, 2));
    return true;
  } catch (error) {
    console.error(`Error saving ${file}:`, error);
    return false;
  }
};

// Main handler function
export default async (req, res) => {
  // CORS headers
  res.setHeader('Access-Control-Allow-Credentials', true);
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET,OPTIONS,POST');
  res.setHeader('Access-Control-Allow-Headers', 'X-CSRF-Token, X-Requested-With, Accept, Accept-Version, Content-Length, Content-MD5, Content-Type, Date, X-Api-Version');

  // Handle OPTIONS request
  if (req.method === 'OPTIONS') {
    res.status(200).end();
    return;
  }

  if (req.method === 'POST') {
    try {
      const voteData = req.body;
      
      if (!voteData || typeof voteData !== 'object') {
        return res.status(400).json({ status: 'error', message: 'Invalid data format' });
      }
      
      // Load current votes
      const votes = loadData('votes.json');
      
      // Process each team's votes
      for (const [teamId, teamVote] of Object.entries(voteData)) {
        // Validate team_id format
        if (!teamId.startsWith('team')) {
          console.log(`Invalid team ID: ${teamId}`);
          continue;
        }
        
        // Ensure team exists in votes data
        if (!votes[teamId]) {
          votes[teamId] = { 'voteCount': 0, 'votes': [] };
        }
        
        // Add the vote
        if (!votes[teamId].votes) {
          votes[teamId].votes = [];
        }
        
        votes[teamId].votes.push(teamVote);
        votes[teamId].voteCount = votes[teamId].votes.length;
      }
      
      // Save updated votes
      const saveSuccess = saveData('votes.json', votes);
      if (!saveSuccess) {
        return res.status(500).json({ status: 'error', message: 'Failed to save votes' });
      }
      
      // Return success
      return res.status(200).json({ status: 'success' });
    } catch (error) {
      console.error('Error in submit-votes:', error);
      return res.status(500).json({ status: 'error', message: error.message });
    }
  } else {
    res.setHeader('Allow', ['POST']);
    return res.status(405).end(`Method ${req.method} Not Allowed`);
  }
};