#!/usr/bin/env python3
"""Inbox poller - watches Plane for new tickets and invokes gatekeeper."""
import os
import sys
import time
import requests
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent / "dev"))
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
PLANE_PROJECT_IDENTIFIER = os.getenv("PLANE_PROJECT_IDENTIFIER", "AGI")

BACKLOG_STATE_ID = os.getenv("BACKLOG_STATE_ID", "1b2f5e1b-d647-4b0e-9bf8-b257307c30b1")
TODO_STATE_ID = os.getenv("TODO_STATE_ID", "5ad5d99b-f9c2-432c-9741-a73d97dd3a3d")
IN_PROGRESS_STATE_ID = os.getenv("IN_PROGRESS_STATE_ID", "c3cefdb0-01c4-4df8-a981-c332960eed09")
DONE_STATE_ID = os.getenv("DONE_STATE_ID", "3f0b18af-0f98-42a0-bbf2-027fff0475b8")

CYCLE_ALPHA = os.getenv("CYCLE_ALPHA_ID", "f395add7-f4e1-4141-99c5-5c609d21683a")
CYCLE_BETA = os.getenv("CYCLE_BETA_ID", "4bb79aee-d494-4b85-b4ff-d8980721d07f")
CYCLE_RELEASE = os.getenv("CYCLE_RELEASE_ID", "09a941ff-213a-4106-a817-81760c3528b3")  # TODO: Move to template.yaml

VERIFY_SSL = False

MAX_TASK_CHARS = 2000
MAX_SUBTASKS_INDICATED = 5

def is_task_too_large(issue) -> tuple[bool, str]:
    """Check if task is too large to process. Returns (is_too_large, reason)."""
    name = issue.get("name", "")
    desc = issue.get("description_stripped", "") or issue.get("description_html", "") or ""
    
    full_text = f"{name} {desc}"
    char_count = len(full_text)
    
    indicators = [" and then ", " and also ", ", then ", " multiple ", " several ",
                  " all of ", " both ", " various ", " numerous "]
    subtask_indicators = sum(1 for ind in indicators if ind.lower() in full_text.lower())
    
    if char_count > MAX_TASK_CHARS:
        return True, f"Task too large: {char_count} chars (max {MAX_TASK_CHARS})"
    
    if subtask_indicators > MAX_SUBTASKS_INDICATED:
        return True, f"Task has {subtask_indicators} sub-tasks indicated (max {MAX_SUBTASKS_INDICATED})"
    
    return False, ""

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

    todo_state = TODO_STATE_ID
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

def add_issue_to_cycle(issue_id: str, cycle_id: str):
    if not PLANE_API_KEY or not cycle_id:
        return None
    
    url = f"{PLANE_URL}/api/v1/workspaces/{PLANE_WORKSPACE}/projects/{PLANE_PROJECT}/cycles/{cycle_id}/cycle-issues/"
    headers = {"x-api-key": PLANE_API_KEY, "Content-Type": "application/json"}
    data = {"issues": [issue_id]}
    
    try:
        response = requests.post(url, json=data, headers=headers, verify=VERIFY_SSL, timeout=30)
        response.raise_for_status()
        return response.json()
    except Exception as e:
        print(f"Error adding to cycle: {e}")
        return None

def move_to_in_progress(issue_id: str):
    if not PLANE_API_KEY:
        return None
    
    url = f"{PLANE_URL}/api/v1/workspaces/{PLANE_WORKSPACE}/projects/{PLANE_PROJECT}/issues/{issue_id}/"
    headers = {"x-api-key": PLANE_API_KEY, "Content-Type": "application/json"}
    data = {"state": IN_PROGRESS_STATE_ID}
    
    try:
        response = requests.patch(url, json=data, headers=headers, verify=VERIFY_SSL, timeout=30)
        response.raise_for_status()
        return response.json()
    except Exception as e:
        print(f"Error moving to in_progress: {e}")
        return None

def move_to_done(issue_id: str):
    if not PLANE_API_KEY:
        return None
    
    url = f"{PLANE_URL}/api/v1/workspaces/{PLANE_WORKSPACE}/projects/{PLANE_PROJECT}/issues/{issue_id}/"
    headers = {"x-api-key": PLANE_API_KEY, "Content-Type": "application/json"}
    data = {"state": DONE_STATE_ID}
    
    try:
        response = requests.patch(url, json=data, headers=headers, verify=VERIFY_SSL, timeout=30)
        response.raise_for_status()
        return response.json()
    except Exception as e:
        print(f"Error moving to done: {e}")
        return None

def process_issue(issue):
    issue_id = issue.get("id")
    sequence_id = issue.get("sequence_id", "?")
    name = issue.get("name", "")
    desc = issue.get("description", "")
    state_id = issue.get("state")
    module = issue.get("module", "None")

    project_id = f"{PLANE_PROJECT_IDENTIFIER}-{sequence_id}"
    
    print(f"\n{'='*50}")
    print(f"Processing: {project_id}: {name}")
    print(f"{'='*50}")

    too_large, reason = is_task_too_large(issue)
    if too_large:
        comment = f"**⚠️ Task Rejected (too large):** {reason}\n\nPlease split into smaller tasks."
        add_plane_comment(issue_id, comment)
        print(f"Task rejected: {reason}")
        return

    ticket_type = name.split("]")[0].strip("[") if "]" in name else "Task"
    description = desc or name

    role = CONFIG["ticket_routing"].get(ticket_type, "SwarmMaster")
    print(f"Route: {ticket_type} -> {role}")

    # Map ticket components for filtering
    component_map = {
        "gatekeeper": ["[ARCH]", "[EXECUTION]", "[AGENT]"],
        "docker": ["[INFRA]", "[DOCKER]"],
        "kafka": ["[ARCH]", "[MONITOR]", "[KAFKA]"],
        "plane": ["[TEMPLATE]", "[OPS]"],
        "jenkins": ["[CI/CD]", "[INFRA]"],
    }
    
    components = []
    for comp, prefixes in component_map.items():
        for prefix in prefixes:
            if prefix in name:
                components.append(comp)
                break
    
    # Detect cycle based on issue prefix
    target_cycle = None
    if ticket_type in ["TEMPLATE"]:
        target_cycle = CYCLE_ALPHA
    elif ticket_type in ["EXECUTION", "ARCH"]:
        target_cycle = CYCLE_BETA
    elif ticket_type in ["CI/CD", "MONITOR", "OPS", "SECURITY"]:
        target_cycle = CYCLE_RELEASE
    else:
        target_cycle = CYCLE_BETA
    
    add_issue_to_cycle(issue_id, target_cycle)
    print(f"Added to cycle: {target_cycle[:8]}...")
    
    metadata = f"\n\n---\n**Project:** {PLANE_PROJECT_IDENTIFIER}\n**Issue:** {project_id}\n**Module:** {module}\n**Components:** {', '.join(components) or 'N/A'}\n**Role:** {role}\n**Cycle:** {target_cycle[:8]}..."

    if role in ["SwarmMaster", "Writer", "Researcher", "Critic"]:
        result = invoke_agent(role, description)
        move_to_in_progress(issue_id)
    else:
        result = invoke_agent(role, description)
        move_to_todo(issue_id)

    if result:
        comment = f"**AI Response ({role}):**\n\n{result[:2000]}{metadata}"
        if len(result) > 2000:
            comment += "\n\n_(truncated)_"
        add_plane_comment(issue_id, comment)
        print(f"Result added - state: In Progress, cycle: {target_cycle[:8]}")
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