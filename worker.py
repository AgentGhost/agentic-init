#!/usr/bin/env python3
"""Worker service - consumes tasks from Kafka and executes with result tracking."""
import os
import sys
import json
import time
import subprocess
from pathlib import Path
from kafka import KafkaConsumer, KafkaProducer

sys.path.insert(0, str(Path(__file__).parent))
from gatekeeper import invoke_agent, CONFIG

os.environ.setdefault("REQUESTS_CA_BUNDLE", "")
os.environ.setdefault("REQUESTS_VERIFY", "false")

KAFKA_BOOTSTRAP = os.getenv("KAFKA_BOOTSTRAP", "localhost:9092")
TASKS_TOPIC = os.getenv("TASKS_TOPIC", "agent-tasks")
RESULTS_TOPIC = os.getenv("RESULTS_TOPIC", "agent-results")

EXECUTION_SANDBOX = os.getenv("EXECUTION_SANDBOX", "false").lower() == "true"

def execute_command(cmd: str) -> dict:
    """Execute a shell command with optional sandboxing."""
    if not EXECUTION_SANDBOX:
        return {"error": "Execution disabled. Enable with EXECUTION_SANDBOX=true"}
    
    try:
        result = subprocess.run(
            cmd,
            shell=True,
            capture_output=True,
            text=True,
            timeout=300,
            cwd=str(Path(__file__).parent)
        )
        return {
            "success": result.returncode == 0,
            "returncode": result.returncode,
            "stdout": result.stdout[:5000],
            "stderr": result.stderr[:1000]
        }
    except subprocess.TimeoutExpired:
        return {"error": "Command timeout after 300s"}
    except Exception as e:
        return {"error": str(e)}

def process_task(task: dict) -> dict:
    """Process a single task: analyze intent, execute, return result."""
    task_type = task.get("type", "Coder")
    description = task.get("description", "")
    command = task.get("command")  # Explicit command to run
    
    result = {"task_id": task.get("id"), "type": task_type}
    
    if command:
        exec_result = execute_command(command)
        result["execution"] = exec_result
    else:
        llm_result = invoke_agent(task_type, description)
        result["llm_response"] = llm_result[:2000]
    
    return result

def main():
    print(f"Worker: Connecting to Kafka at {KAFKA_BOOTSTRAP}")
    print(f"Topics: {TASKS_TOPIC} → {RESULTS_TOPIC}")
    print(f"Execution sandbox: {'ENABLED' if EXECUTION_SANDBOX else 'DISABLED'}")
    
    try:
        consumer = KafkaConsumer(
            TASKS_TOPIC,
            bootstrap_servers=KAFKA_BOOTSTRAP,
            value_deserializer=lambda m: json.loads(m.decode()),
            auto_offset_reset='earliest',
            group_id='agentic-worker'
        )
        producer = KafkaProducer(
            bootstrap_servers=KAFKA_BOOTSTRAP,
            value_serializer=lambda v: json.dumps(v).encode()
        )
        print("Connected to Kafka ✓")
    except Exception as e:
        print(f"Kafka connection failed: {e}")
        print("Running in fallback (local) mode...")
        consumer = None
        producer = None
    
    if consumer:
        print(f"\nListening for tasks on '{TASKS_TOPIC}'...")
        for message in consumer:
            task = message.value
            print(f"\nReceived: {task.get('id', 'unknown')}")
            
            result = process_task(task)
            
            if producer:
                producer.send(RESULTS_TOPIC, value=result)
                print(f"Result→ {RESULTS_TOPIC}")
            else:
                print(f"Result: {json.dumps(result, indent=2)[:500]}")
    else:
        print("No Kafka - exiting")

if __name__ == "__main__":
    main()