#!/usr/bin/env python3
"""Plane issue quality gate - validates cycle and module assignment."""
import sys
import os
import requests

API_KEY = os.environ.get('PLANE_API_KEY', 'plane_api_606d614153f34b65bb5fbd9cf403004a')
WS = 'agentic-projects'
PROJECT = '2355e826-805c-4028-9fc5-14327948e5fb'
HEAD = {'x-api-key': API_KEY}

BASE = f'http://localhost/api/v1/workspaces/{WS}/projects/{PROJECT}'

def get_cycles():
    r = requests.get(f'{BASE}/cycles/', headers=HEAD, timeout=30)
    return {c['name']: c['id'] for c in r.json().get('results', [])}

def get_modules():
    r = requests.get(f'{BASE}/modules/', headers=HEAD, timeout=30)
    return {m['name']: m['id'] for m in r.json().get('results', [])}

def check_cycle_issues():
    issues_by_cycle = {}
    cycles = get_cycles()
    for name, cid in cycles.items():
        r = requests.get(f'{BASE}/cycles/{cid}/', headers=HEAD, timeout=30)
        data = r.json()
        issues_by_cycle[name] = data.get('total_issues', 0)
    return issues_by_cycle

def check_module_issues():
    issues_by_module = {}
    modules = get_modules()
    for name, mid in modules.items():
        r = requests.get(f'{BASE}/modules/{mid}/', headers=HEAD, timeout=30)
        data = r.json()
        issues_by_module[name] = data.get('total_issues', 0)
    return issues_by_module

def main():
    print("=== Plane Issue Quality Gate ===")
    print("Checking: cycle and module assignment\n")
    
    by_cycle = check_cycle_issues()
    by_module = check_module_issues()
    
    for cycle_name, count in by_cycle.items():
        if not count:
            print(f"[WARNING] No issues in cycle: {cycle_name}")
    
    for module_name, count in by_module.items():
        if not count:
            print(f"[WARNING] No issues in module: {module_name}")
    
    total_cycles = sum(v for v in by_cycle.values())
    total_modules = sum(v for v in by_module.values())
    
    print(f"\nTotal: {total_cycles} in cycles, {total_modules} in modules")
    
    if total_cycles == 0 and total_modules == 0:
        print("[ERROR] No issues assigned to any cycle or module!")
        return 1
    
    print("[OK] Quality gate passed")
    return 0

if __name__ == '__main__':
    sys.exit(main())