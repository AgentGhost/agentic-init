#!/usr/bin/env python3
"""Plane restore script."""
import os
import json
import requests

API_KEY = os.environ.get('PLANE_API_KEY', 'plane_api_606d614153f34b65bb5fbd9cf403004a')
PROJECT = '2355e826-805c-4028-9fc5-14327948e5fb'
WS = 'agentic-projects'
HEAD = {'x-api-key': API_KEY, 'Content-Type': 'application/json'}

def create_issue(name, parent=None, description=''):
    payload = {'name': name}
    if parent:
        payload['parent'] = parent
    if description:
        payload['description'] = description
    
    r = requests.post(
        f'http://localhost/api/v1/workspaces/{WS}/projects/{PROJECT}/issues/',
        headers=HEAD,
        json=payload
    )
    if r.status_code in (200, 201):
        return r.json().get('id')
    return None

def main():
    import sys
    if len(sys.argv) < 2:
        print('Usage: python restore_plane.py <backup_file>')
        return
    
    with open(sys.argv[1]) as f:
        data = json.load(f)
    
    Base = f'http://localhost/api/v1/workspaces/{WS}/projects/{PROJECT}'
    
    # Create EPICs first
    epics = {}
    for issue in data.get('issues', []):
        if not issue.get('parent'):
            eid = create_issue(issue['name'], description=issue.get('description_html', ''))
            if eid:
                epics[issue['name']] = eid
                print(f'Created EPIC: {issue["name"]}')
    
    # Create children
    for issue in data.get('issues', []):
        if issue.get('parent'):
            parent_id = epics.get(issue.get('parent', {}).get('name', ''))
            if parent_id:
                cid = create_issue(issue['name'], parent=parent_id, description=issue.get('description_html', ''))
                print(f'Created: {issue["name"]}')
    
    print(f'Restored: {len(epics)} EPICs')

if __name__ == '__main__':
    main()