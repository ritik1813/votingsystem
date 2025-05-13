import { readFileSync } from 'fs';
import path from 'path';

// Helper function to load data
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

export default async (req, res) => {
  // CORS headers
  res.setHeader('Access-Control-Allow-Credentials', true);
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET,OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'X-CSRF-Token, X-Requested-With, Accept, Accept-Version, Content-Length, Content-MD5, Content-Type, Date, X-Api-Version');

  // Handle OPTIONS request
  if (req.method === 'OPTIONS') {
    res.status(200).end();
    return;
  }

  if (req.method === 'GET') {
    try {
      const votes = loadData('votes.json');
      const results = loadData('results.json');
      
      // Calculate vote counts only
      for (const [teamId, teamData] of Object.entries(votes)) {
        if (teamData.votes) {
          votes[teamId].voteCount = teamData.votes.length;
        }
      }
      
      return res.status(200).json({
        votes: votes,
        results: results
      });
    } catch (error) {
      console.error('Error in voting-status:', error);
      return res.status(500).json({ status: 'error', message: error.message });
    }
  } else {
    res.setHeader('Allow', ['GET']);
    return res.status(405).end(`Method ${req.method} Not Allowed`);
  }
};