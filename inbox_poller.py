#!/usr/bin/env python3
"""Inbox poller - watches Plane for new tickets and invokes gatekeeper."""
import os
import sys
import time
import requests
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from gatekeeper import invoke_agent, CONFIG

os.environ.setdefault("REQUESTS_CA_BUNDLE", "")
os.environ.setdefault("REQUESTS_VERIFY", "false")
os.environ.setdefault("CURL_CA_BUNDLE", "")

POLL_INTERVAL = int(os.getenv("POLL_INTERVAL", "30"))

PLANE_URL = os.getenv("PLANE_URL", "http://localhost")
PLANE_API_KEY = os.getenv("PLANE_API_KEY")
PLANE_WORKSPACE = os.getenv("PLANE_WORKSPACE", "agentic-projects")
PLANE_PROJECT = os.getenv("PLANE_PROJECT")  # Required: set via .env or config/template.yaml
PLANE_WORKSPACE = os.getenv("PLANE_WORKSPACE", "agentic-projects")

BACKLOG_STATE_ID = os.getenv("BACKLOG_STATE_ID", "1b2f5e1b-d647-4b0e-9bf8-b257307c30b1")  # TODO: Move to template.yaml

VERIFY_SSL = False

def get_new_issues():
    if not PLANE_API_KEY:
        print("PLANE_API_KEY not set")
        return []

    url = f"{PLANE_URL}/api/v1/workspaces/{PLANE_WORKSPACE}/projects/{PLANE_PROJECT}/issues/"
    headers = {"x-api-key": PLANE_API_KEY, "Content-Type": "application/json"}

    try:
        response = requests.get(url, headers=headers, verify=VERIFY_SSL, timeout=30)
        response.raise_for_status()
        issues = response.json().get("results", [])

        new = []
        for issue in issues:
            if issue.get("state") == BACKLOG_STATE_ID:
                new.append(issue)
        return new
    except Exception as e:
        print(f"Error fetching issues: {e}")
        return []

def add_plane_comment(issue_id: str, comment: str):
    if not PLANE_API_KEY:
        return None

    url = f"{PLANE_URL}/api/v1/workspaces/{PLANE_WORKSPACE}/projects/{PLANE_PROJECT}/issues/{issue_id}/"
    headers = {"x-api-key": PLANE_API_KEY, "Content-Type": "application/json"}
    data = {"description_html": f"<p>{comment.replace(chr(10), '<br>')}</p>"}

    try:
        response = requests.patch(url, json=data, headers=headers, verify=VERIFY_SSL, timeout=30)
        response.raise_for_status()
        return response.json()
    except Exception as e:
        print(f"Error updating issue: {e}")
        return None

def move_to_todo(issue_id: str):
    if not PLANE_API_KEY:
        return None

    todo_state = "d44db477-3397-4a88-9bd0-4cb86a04fc60"
    url = f"{PLANE_URL}/api/v1/workspaces/{PLANE_WORKSPACE}/projects/{PLANE_PROJECT}/issues/{issue_id}/"
    headers = {"x-api-key": PLANE_API_KEY, "Content-Type": "application/json"}
    data = {"state": todo_state}

    try:
        response = requests.patch(url, json=data, headers=headers, verify=VERIFY_SSL, timeout=30)
        response.raise_for_status()
        return response.json()
    except Exception as e:
        print(f"Error moving issue: {e}")
        return None

def process_issue(issue):
    issue_id = issue.get("id")
    name = issue.get("name", "")
    desc = issue.get("description", "")
    state_id = issue.get("state")

    print(f"\n{'='*50}")
    print(f"Processing: {name}")
    print(f"{'='*50}")

    ticket_type = name.split("]")[0].strip("[") if "]" in name else "Task"
    description = desc or name

    role = CONFIG["ticket_routing"].get(ticket_type, "Coder")
    print(f"Route: {ticket_type} -> {role}")

    result = invoke_agent(role, description)

    if result:
        comment = f"**AI Response ({role}):**\n\n{result[:2000]}"
        if len(result) > 2000:
            comment += "\n\n_(truncated)_"
        add_plane_comment(issue_id, comment)
        print(f"Result added to issue")
    else:
        print(f"No result returned")

    move_to_todo(issue_id)
    print(f"Moved to In Progress")

def main():
    print(f"Inbox Poller started (interval: {POLL_INTERVAL}s)")
    print("Press Ctrl+C to stop\n")

    processed = set()

    while True:
        try:
            issues = get_new_issues()
            new_issues = [i for i in issues if i.get("id") not in processed]

            if new_issues:
                print(f"\nFound {len(new_issues)} new issue(s)")
                for issue in new_issues:
                    process_issue(issue)
                    processed.add(issue.get("id"))
            else:
                print(f".", end="", flush=True)

            time.sleep(POLL_INTERVAL)

        except KeyboardInterrupt:
            print("\n\nStopped")
            break
        except Exception as e:
            print(f"\nError: {e}")
            time.sleep(POLL_INTERVAL)

if __name__ == "__main__":
    main()