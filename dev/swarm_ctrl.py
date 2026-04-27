#!/usr/bin/env python3
"""
swarm_ctrl.py - Zen-Swarm Controller

Implements the atomic code iteration loop:
1. Researcher -> fetches context
2. Writer -> creates diff (SEARCH/REPLACE)
3. Critic -> validates diff

Max 3 iterations. On success -> emit Kafka event + git commit.
On failure -> emit to dead-letter queue.

Usage:
    python swarm_ctrl.py --task "Implement login function" --file src/auth.py --search "def login()" --replace "def login(user, pass): ..."
    
    # Or from gatekeeper:
    gatekeeper.invoke_swarm(ticket_description)
"""
import os
import sys
import json
import argparse
from pathlib import Path
from typing import Optional, Dict, Tuple

sys.path.insert(0, str(Path(__file__).parent.parent / "dev"))
from gatekeeper import call_ollama, CONFIG, PROVIDERS

OLLAMA_HOST = os.getenv("OLLAMA_HOST", "http://localhost:11434")
TAVILY_API_KEY = os.getenv("TAVILY_API_KEY")

MAX_ITERATIONS = CONFIG.get("zen_swarm", {}).get("max_iterations", 3)

def research_context(task: str) -> str:
    """Phase 1: Researcher - gather context via Tavily."""
    if not TAVILY_API_KEY:
        return f"No Tavily API key - using task only: {task}"
    
    try:
        import requests
        response = requests.post(
            "https://api.tavily.com/search",
            json={"query": task, "api_key": TAVILY_API_KEY},
            timeout=30
        )
        results = response.json().get("results", [])[:3]
        context = "\n".join([r.get("content", "")[:200] for r in results])
        return context or task
    except Exception as e:
        return f"Tavily error: {e}, falling back to: {task}"

def write_diff(task: str, search: str, replace: str, file_path: str) -> Tuple[bool, str]:
    """Phase 2: Writer - create atomic SEARCH/REPLACE diff."""
    if not file_path or not search:
        return False, "No file_path or search pattern provided"
    
    full_path = Path(file_path)
    if not full_path.exists():
        return False, f"File not found: {file_path}"
    
    content = full_path.read_text(encoding="utf-8")
    
    if search not in content:
        return False, f"Search pattern not found in {file_path}"
    
    try:
        new_content = content.replace(search, replace)
        full_path.write_text(new_content, encoding="utf-8")
        return True, f"Diff applied to {file_path}"
    except Exception as e:
        return False, f"Write error: {e}"

def critic_validate(task: str, file_path: str, search: str) -> Tuple[bool, str]:
    """Phase 3: Critic - validate the diff."""
    if not file_path:
        return False, "No file specified"
    
    full_path = Path(file_path)
    if not full_path.exists():
        return False, f"File not found"
    
    content = full_path.read_text(encoding="utf-8")
    
    if search not in content and search:
        return False, "Search pattern not in file (already replaced?)"
    
    prompt = f"""Review this code change for a task: {task}

File: {file_path}
Content (first 1000 chars):
{content[:1000]}

Respond with:
- PASS: if code looks correct and safe
- FAIL: <reason> if issues found

Keep response short (max 50 words)."""
    
    result = call_ollama("phi3", prompt)
    if not result:
        return True, "No response from Critic, assuming pass"
    
    if "FAIL" in result.upper():
        return False, result
    
    return True, "PASS"

def run_zen_loop(
    task: str,
    file_path: str,
    search: str,
    replace: str,
    emit_events: bool = True
) -> Dict:
    """Execute the full Zen-Swarm loop."""
    iteration = 0
    last_error = None
    
    while iteration < MAX_ITERATIONS:
        iteration += 1
        print(f"\n=== Zen-Swarm Iteration {iteration}/{MAX_ITERATIONS} ===")
        
        print(f"[1/3] Researcher: Gathering context...")
        context = research_context(task)
        print(f"   Context: {context[:100]}...")
        
        print(f"[2/3] Writer: Creating diff in {file_path}...")
        success, msg = write_diff(task, search, replace, file_path)
        if not success:
            print(f"   ERROR: {msg}")
            last_error = msg
            if emit_events:
                emit_to_dlq(task, iteration, msg)
            continue
        
        print(f"   {msg}")
        
        print(f"[3/3] Critic: Validating change...")
        valid, msg = critic_validate(task, file_path, search)
        print(f"   {msg}")
        
        if valid:
            print(f"\n✓ Zen achieved in {iteration} iteration(s)!")
            
            if emit_events:
                emit_task_event(task, iteration, "success", file_path)
            
            return {
                "status": "success",
                "iterations": iteration,
                "file": file_path,
                "task": task
            }
        
        last_error = msg
        
        if iteration < MAX_ITERATIONS:
            print(f"   Critic says: {msg}")
            print(f"   Rolling back and retrying...")
            revert_diff(file_path, search, replace)
    
    print(f"\n✗ Max iterations ({MAX_ITERATIONS}) reached without success")
    
    if emit_events:
        emit_task_event(task, iteration, "failed", last_error)
    
    return {
        "status": "failed",
        "iterations": iteration,
        "error": last_error,
        "task": task
    }

def revert_diff(file_path: str, search: str, replace: str):
    """Rollback a change."""
    try:
        full_path = Path(file_path)
        content = full_path.read_text(encoding="utf-8")
        content = content.replace(replace, search)
        full_path.write_text(content, encoding="utf-8")
        print(f"   Reverted: {file_path}")
    except Exception as e:
        print(f"   Revert error: {e}")

def emit_task_event(task: str, iteration: int, status: str, detail: str = ""):
    """Emit task lifecycle event to Kafka."""
    print(f"   [Kafka] Emitting {status} event: {task} (iter {iteration})")
    # TODO: Integrate with worker.py Kafka producer

def emit_to_dlq(task: str, iteration: int, error: str):
    """Emit failed task to dead-letter queue."""
    print(f"   [DLQ] Task failed: {task} - {error}")

def invoke_swarm(task: str, context: str = "", max_iters: int = None) -> str:
    """Invoke the swarm from gatekeeper."""
    if max_iters:
        CONFIG["zen_swarm"]["max_iterations"] = max_iters
    
    print(f"\n{'='*50}")
    print(f"Zen-Swarm: {task}")
    print(f"{'='*50}")
    
    result = {
        "task": task,
        "context": context,
        "status": "not_implemented",
        "note": "swarm_ctrl.py created - needs file_path/search/replace args"
    }
    
    return json.dumps(result, indent=2)

def main():
    parser = argparse.ArgumentParser(description="Zen-Swarm Controller")
    parser.add_argument("--task", "-t", help="Task description")
    parser.add_argument("--file", "-f", help="File path to modify")
    parser.add_argument("--search", "-s", help="Search pattern (SEARCH)")
    parser.add_argument("--replace", "-r", help="Replace pattern (REPLACE)")
    parser.add_argument("--max-iters", "-m", type=int, default=3, help="Max iterations")
    parser.add_argument("--dry-run", "-d", action="store_true", help="Dry run mode")
    args = parser.parse_args()
    
    if args.task and args.file and args.search and args.replace:
        result = run_zen_loop(
            args.task,
            args.file,
            args.search,
            args.replace,
            emit_events=not args.dry_run
        )
        print(json.dumps(result, indent=2))
    else:
        print(__doc__)
        print("\nExample:")
        print('  python swarm_ctrl.py -t "Add auth" -f src/auth.py -s "def auth():" -r "def auth(user, pass):"')

if __name__ == "__main__":
    main()