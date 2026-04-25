#!/usr/bin/env python3
"""
gatekeeper.py - Agentic Factory Core Router
============================================
Dieses Skript ist das Herzstück der Agentic Software Factory.
Es routet Plane-Tickets intelligent an Cloud- oder Lokal-Agenten.

- Cloud-Agenten (teuer): Product Owner, Architect -> Claude 3.5 Sonnet
- Lokal-Agenten (kostenlos): Coder, Tester, Reviewer -> Ollama
"""

import os
import sys
import requests
from typing import Optional
from dotenv import load_dotenv

# ==========================================
# KONFIGURATION
# ==========================================
load_dotenv()

ANTHROPIC_KEY = os.getenv("ANTHROPIC_API_KEY")
OLLAMA_HOST = os.getenv("OLLAMA_HOST", "http://localhost:11434")
PLANE_API_KEY = os.getenv("PLANE_API_KEY")
PLANE_URL = os.getenv("PLANE_URL", "http://localhost:8080")

# Rollen, die Cloud-Tokens verbrauchen dürfen
CLOUD_AGENTS = ["PO", "Architect"]

# Model-Zuordnung für lokale Agenten
LOCAL_MODELS = {
    "Coder": "qwen2.5-coder:14b",
    "Tester": "llama3.1:8b",
    "Reviewer": "phi3:mini"
}


# ==========================================
# SICHERHEITSCHECK
# ==========================================
def validate_config() -> bool:
    """Prüft ob alle erforderlichen Konfigurationen vorhanden sind."""
    errors = []
    
    if not ANTHROPIC_KEY:
        errors.append("❌ ANTHROPIC_API_KEY nicht in .env gesetzt!")
    if not PLANE_API_KEY:
        errors.append("❌ PLANE_API_KEY nicht in .env gesetzt!")
    
    if errors:
        for error in errors:
            print(error)
        return False
    
    print("✅ Konfiguration validiert")
    return True


# ==========================================
# CLOUD EXECUTION (Teuer - limitiert)
# ==========================================
def invoke_cloud_agent(role: str, prompt: str) -> Optional[str]:
    """
    Nutzt den teuren Anthropic API Key.
    Darf NUR für CLOUD_AGENTS aufgerufen werden!
    """
    if role not in CLOUD_AGENTS:
        raise PermissionError(
            f"🚫 SICHERHEITS-BLOCK: Rolle '{role}' darf keine Cloud-Tokens verbrauchen!"
        )
    
    print(f"☁️  [CLOUD - {role}] Sende Request an Anthropic...")
    
    try:
        headers = {
            "x-api-key": ANTHROPIC_KEY,
            "anthropic-version": "2023-06-01",
            "content-type": "application/json"
        }
        payload = {
            "model": "claude-3-5-sonnet-20240620",
            "max_tokens": 2048,
            "system": f"Du bist ein {role} Agent in einer Agentic Software Factory.",
            "messages": [{"role": "user", "content": prompt}]
        }
        
        response = requests.post(
            "https://api.anthropic.com/v1/messages",
            json=payload,
            headers=headers,
            timeout=30
        )
        response.raise_for_status()
        
        result = response.json()['content'][0]['text']
        print(f"✅ Response erhalten ({len(result)} Zeichen)")
        return result
        
    except requests.exceptions.RequestException as e:
        print(f"❌ Cloud Request fehlgeschlagen: {e}")
        return None


# ==========================================
# LOCAL EXECUTION (Kostenlos via Ollama)
# ==========================================
def invoke_local_agent(role: str, prompt: str) -> Optional[str]:
    """
    Nutzt RX 6900 XT via Ollama.
    Kostenlos und ohne externe API Keys!
    """
    if role not in LOCAL_MODELS:
        raise ValueError(f"❌ Unbekannte lokale Rolle: {role}")
    
    model = LOCAL_MODELS[role]
    print(f"🖥️  [LOCAL - {role}] Sende Request an Ollama ({model})...")
    
    try:
        payload = {
            "model": model,
            "prompt": f"System-Rolle: {role}\n\n{prompt}",
            "stream": False
        }
        
        response = requests.post(
            f"{OLLAMA_HOST}/api/generate",
            json=payload,
            timeout=60
        )
        response.raise_for_status()
        
        result = response.json()['response']
        print(f"✅ Response erhalten ({len(result)} Zeichen)")
        return result
        
    except requests.exceptions.RequestException as e:
        print(f"❌ Ollama Request fehlgeschlagen: {e}")
        print(f"💡 Stellen Sie sicher, dass Ollama läuft: ollama serve")
        return None


# ==========================================
# GATEKEEPER - TICKET ROUTING
# ==========================================
def process_plane_ticket(ticket_type: str, ticket_description: str) -> Optional[str]:
    """
    Das Herzstück: Intelligentes Routing basierend auf Ticket-Typ.
    
    Strategic Tickets (teuer): Cloud
    Operational Tickets (schnell): Lokal
    """
    print(f"\n📋 Verarbeite Ticket (Typ: {ticket_type})")
    print("=" * 60)
    
    if ticket_type in ["Epic", "Strategic_Vision"]:
        return invoke_cloud_agent("PO", f"Zerlege diese Vision:\n\n{ticket_description}")
    
    elif ticket_type == "Architecture_Blueprint":
        return invoke_cloud_agent(
            "Architect",
            f"Erstelle einen Terraform/Kafka Blueprint für:\n\n{ticket_description}"
        )
    
    elif ticket_type in ["Feature", "Task"]:
        return invoke_local_agent("Coder", f"Implementiere:\n\n{ticket_description}")
    
    elif ticket_type == "Test":
        return invoke_local_agent("Tester", f"Schreibe Tests für:\n\n{ticket_description}")
    
    elif ticket_type == "Code_Review":
        return invoke_local_agent("Reviewer", f"Prüfe diesen Code:\n\n{ticket_description}")
    
    else:
        print(f"⚠️  Unbekannter Ticket-Typ: {ticket_type}")
        return None


# ==========================================
# MAIN DEMO
# ==========================================
def main():
    print("🏭 Agentic Software Factory - Gatekeeper Router")
    print("=" * 60)
    print("")
    
    if not validate_config():
        sys.exit(1)
    
    print("")
    
    # Demo-Tickets
    test_tickets = [
        {
            "type": "Strategic_Vision",
            "desc": "Baue ein verteiltes Login-System mit OAuth2 + Kafka Event Stream"
        },
        {
            "type": "Task",
            "desc": "Implementiere auth_service.py mit JWT Token Support"
        },
        {
            "type": "Test",
            "desc": "Schreibe Unit-Tests für Token Validation und Refresh Flow"
        },
        {
            "type": "Code_Review",
            "desc": "def validate_token(token: str) -> bool:\n    return len(token) > 32"
        }
    ]
    
    for ticket in test_tickets:
        result = process_plane_ticket(ticket["type"], ticket["desc"])
        if result:
            print(f"📄 Output:\n{result}\n")
        else:
            print("❌ Ticket-Verarbeitung fehlgeschlagen\n")


if __name__ == "__main__":
    main()
