#!/usr/bin/env python3
"""Plane backup script."""
import os
import json
import requests
from datetime import datetime

API_KEY = os.environ.get('PLANE_API_KEY', 'plane_api_606d614153f34b65bb5fbd9cf403004a')
PROJECT = '2355e826-805c-4028-9fc5-14327948e5fb'
WS = 'agentic-projects'
HEAD = {'x-api-key': API_KEY}

def main():
    Base = f'http://localhost/api/v1/workspaces/{WS}/projects/{PROJECT}'
    
    r_issues = requests.get(f'{Base}/issues/', headers=HEAD, timeout=30)
    r_cycles = requests.get(f'{Base}/cycles/', headers=HEAD, timeout=30)
    r_modules = requests.get(f'{Base}/modules/', headers=HEAD, timeout=30)
    
    data = {
        'timestamp': datetime.now().isoformat(),
        'workspace': WS,
        'project': PROJECT,
        'issues': r_issues.json().get('results', []),
        'cycles': r_cycles.json().get('results', []),
        'modules': r_modules.json().get('results', [])
    }
    
    os.makedirs('ops/backups', exist_ok=True)
    filename = f"ops/backups/{datetime.now().strftime('%Y%m%d_%H%M%S')}_{PROJECT}_backup.json"
    with open(filename, 'w') as f:
        json.dump(data, f, indent=2)
    
    print(f'Backup: {len(data["issues"])} issues, {len(data["cycles"])} cycles, {len(data["modules"])} modules')
    print(f'Saved to: {filename}')

if __name__ == '__main__':
    main()