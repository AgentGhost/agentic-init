#!/usr/bin/env python3
"""Plane restore script."""
import os
import json
import time
import requests

API_KEY = os.environ.get('PLANE_API_KEY', 'plane_api_d317bc99a02c4812abc0374aa173cde5')
PROJECT = 'fe5033a4-8532-479d-b2a9-a01e37e2dbd2'
WS = 'agentic-projects'
HEAD = {'x-api-key': API_KEY, 'Content-Type': 'application/json'}

# Rate limiting
MAX_RETRIES = 3
RETRY_DELAY = 2

def create_issue(name, parent=None, description=''):
    payload = {'name': name}
    if parent:
        payload['parent'] = parent
    if description:
        payload['description'] = description
    
    # Retry on rate limit
    for attempt in range(MAX_RETRIES):
        r = requests.post(
            f'http://localhost/api/v1/workspaces/{WS}/projects/{PROJECT}/issues/',
            headers=HEAD,
            json=payload
        )
        if r.status_code == 429:
            print(f'Rate limited, waiting {RETRY_DELAY}s...')
            time.sleep(RETRY_DELAY)
            continue
        if r.status_code in (200, 201):
            new_id = r.json().get('id')
            print(f'OK: {name[:40]}')
            return new_id
        print(f'FAIL: {name[:40]} - {r.status_code}')
        return None
    return None

def main():
    import sys
    if len(sys.argv) < 2:
        print('Usage: python restore_plane.py <backup_file>')
        return
    
    with open(sys.argv[1]) as f:
        data = json.load(f)
    
    Base = f'http://localhost/api/v1/workspaces/{WS}/projects/{PROJECT}'
    
    # First pass: Create EPICs and store mapping from old ID -> new ID
    old_to_new = {}
    for issue in data.get('issues', []):
        if not issue.get('parent'):
            new_id = create_issue(issue['name'], description=issue.get('description_html', ''))
            if new_id:
                old_to_new[issue['id']] = new_id
                print(f'Created EPIC: {issue["name"]}')
    
    # Second pass: Create children with correct parent ID
    for issue in data.get('issues', []):
        parent = issue.get('parent')
        if parent:
            new_parent_id = old_to_new.get(parent)
            if new_parent_id:
                cid = create_issue(issue['name'], parent=new_parent_id, description=issue.get('description_html', ''))
                print(f'Created: {issue["name"]}')

    print(f'Restored: {len(old_to_new)} EPICs + children')
    
    print(f'Restored: {len(old_to_new)} EPICs + children')

if __name__ == '__main__':
    main()