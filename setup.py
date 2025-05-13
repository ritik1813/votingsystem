#!/usr/bin/env python
import os
import shutil
import sys

def setup_project():
    print("Setting up the Hackathon Voting System...")
    
    # Create directory structure
    os.makedirs('data', exist_ok=True)
    os.makedirs('static', exist_ok=True)
    os.makedirs('templates', exist_ok=True)
    
    # Convert React components to standalone JS files
    components = [
        ('App.jsx', 'static/App.js'),
        ('VotingForm.jsx', 'static/VotingForm.js'),
        ('ResultsDisplay.jsx', 'static/ResultsDisplay.js')
    ]
    
    for src, dest in components:
        if os.path.exists(src):
            with open(src, 'r') as f:
                content = f.read()
            
            # Remove imports
            lines = content.split('\n')
            filtered_lines = []
            for line in lines:
                if not line.startswith('import ') and not line.startswith('export default'):
                    filtered_lines.append(line)
            
            # Write the standalone component
            with open(dest, 'w') as f:
                f.write('\n'.join(filtered_lines))
            
            print(f"Converted {src} to {dest}")
        else:
            print(f"Warning: {src} not found. Please make sure you have all component files.")
    
    # Create index.html if it doesn't exist
    if not os.path.exists('templates/index.html'):
        print("Warning: templates/index.html not found.")
    
    # Create app.py if it doesn't exist
    if not os.path.exists('app.py'):
        print("Warning: app.py not found.")
    
    print("\nSetup complete! To run the application:")
    print("1. Activate your conda environment:")
    print("   conda activate hackathon-voting-system")
    print("2. Run the Flask application:")
    print("   python app.py")
    print("3. Open your browser and navigate to http://localhost:5000")
    print("\nAdmin access for results view:")
    print("- Username: admin")
    print("- Password: admin123")

if __name__ == "__main__":
    setup_project()