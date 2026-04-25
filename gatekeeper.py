#!/usr/bin/env python3
"""
gatekeeper.py - Agentic Factory Multi-Provider Router
======================================================
Routet Tasks intelligent zwischen LOKALEN und FREIEN CLOUD-Agenten.

Cloud-Provider (alle haben FREE Tier!):
- Google Gemini      (15 RPM, 1M tokens/day FREE)
- Groq               (30 RPM, schnellste Inference, FREE)
- OpenRouter         (FREE Modelle: llama-3.1-70b, gemini-flash)
- HuggingFace        (Inference API FREE Tier)
- Anthropic          (optional, paid)

Lokal via Ollama:
- qwen2.5-coder:14b  (Coder)
- llama3.1:8b        (Tester)
- phi3:mini          (Reviewer)
"""

import os
import sys
import requests
from typing import Optional, Dict
from dotenv import load_dotenv

# ==========================================
# KONFIGURATION
# ==========================================
load_dotenv()

# Lokal
OLLAMA_HOST = os.getenv("OLLAMA_HOST", "http://localhost:11434")

# Cloud Providers (alle FREE Tier verfügbar!)
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")          # aistudio.google.com
GROQ_API_KEY = os.getenv("GROQ_API_KEY")              # console.groq.com
OPENROUTER_API_KEY = os.getenv("OPENROUTER_API_KEY")  # openrouter.ai
HF_API_KEY = os.getenv("HF_API_KEY")                  # huggingface.co
ANTHROPIC_KEY = os.getenv("ANTHROPIC_API_KEY")        # console.anthropic.com (optional, paid)


# ==========================================
# AGENT-ZU-MODELL ROUTING
# ==========================================
ROUTING_TABLE = {
    # Strategische Rollen → Free Cloud (Gemini ist großzügigster)
    "PO": {
        "primary": "gemini",
        "model": "gemini-2.0-flash",
        "fallback": "groq",
        "fallback_model": "llama-3.3-70b-versatile"
    },
    "Architect": {
        "primary": "gemini",
        "model": "gemini-2.0-flash",
        "fallback": "openrouter",
        "fallback_model": "google/gemini-flash-1.5"
    },

    # Operative Rollen → Local Ollama (kostenlos, privat)
    "Coder": {
        "primary": "ollama",
        "model": "qwen2.5-coder:14b",
        "fallback": "groq",
        "fallback_model": "llama-3.3-70b-versatile"
    },
    "Tester": {
        "primary": "ollama",
        "model": "llama3.1:8b",
        "fallback": "groq",
        "fallback_model": "llama-3.1-8b-instant"
    },
    "Reviewer": {
        "primary": "ollama",
        "model": "phi3:mini",
        "fallback": "groq",
        "fallback_model": "llama-3.1-8b-instant"
    }
}


# ==========================================
# PROVIDER IMPLEMENTATIONS
# ==========================================

def call_ollama(model: str, prompt: str) -> Optional[str]:
    """Lokales Ollama (kostenlos, GPU-beschleunigt)."""
    print(f"   🖥️  Ollama → {model}")
    try:
        response = requests.post(
            f"{OLLAMA_HOST}/api/generate",
            json={"model": model, "prompt": prompt, "stream": False},
            timeout=120
        )
        response.raise_for_status()
        return response.json()["response"]
    except Exception as e:
        print(f"   ❌ Ollama Fehler: {e}")
        return None


def call_gemini(model: str, prompt: str) -> Optional[str]:
    """Google Gemini (FREE: 15 RPM, 1M tokens/day)."""
    if not GEMINI_API_KEY:
        print(f"   ⚠️  GEMINI_API_KEY fehlt")
        return None

    print(f"   ☁️  Gemini → {model}")
    try:
        url = f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent"
        response = requests.post(
            url,
            params={"key": GEMINI_API_KEY},
            json={"contents": [{"parts": [{"text": prompt}]}]},
            timeout=30
        )
        response.raise_for_status()
        return response.json()["candidates"][0]["content"]["parts"][0]["text"]
    except Exception as e:
        print(f"   ❌ Gemini Fehler: {e}")
        return None


def call_groq(model: str, prompt: str) -> Optional[str]:
    """Groq (FREE: 30 RPM, schnellste Inference < 1s)."""
    if not GROQ_API_KEY:
        print(f"   ⚠️  GROQ_API_KEY fehlt")
        return None

    print(f"   ⚡ Groq → {model}")
    try:
        response = requests.post(
            "https://api.groq.com/openai/v1/chat/completions",
            headers={"Authorization": f"Bearer {GROQ_API_KEY}"},
            json={
                "model": model,
                "messages": [{"role": "user", "content": prompt}],
                "max_tokens": 2048
            },
            timeout=30
        )
        response.raise_for_status()
        return response.json()["choices"][0]["message"]["content"]
    except Exception as e:
        print(f"   ❌ Groq Fehler: {e}")
        return None


def call_openrouter(model: str, prompt: str) -> Optional[str]:
    """OpenRouter (FREE Modelle wie :free Suffix)."""
    if not OPENROUTER_API_KEY:
        print(f"   ⚠️  OPENROUTER_API_KEY fehlt")
        return None

    print(f"   🌐 OpenRouter → {model}")
    try:
        response = requests.post(
            "https://openrouter.ai/api/v1/chat/completions",
            headers={
                "Authorization": f"Bearer {OPENROUTER_API_KEY}",
                "HTTP-Referer": "https://github.com/agentic-init",
                "X-Title": "Agentic Factory"
            },
            json={
                "model": model,
                "messages": [{"role": "user", "content": prompt}],
                "max_tokens": 2048
            },
            timeout=30
        )
        response.raise_for_status()
        return response.json()["choices"][0]["message"]["content"]
    except Exception as e:
        print(f"   ❌ OpenRouter Fehler: {e}")
        return None


def call_huggingface(model: str, prompt: str) -> Optional[str]:
    """HuggingFace Inference API (FREE Tier)."""
    if not HF_API_KEY:
        print(f"   ⚠️  HF_API_KEY fehlt")
        return None

    print(f"   🤗 HuggingFace → {model}")
    try:
        response = requests.post(
            f"https://api-inference.huggingface.co/models/{model}",
            headers={"Authorization": f"Bearer {HF_API_KEY}"},
            json={"inputs": prompt, "parameters": {"max_new_tokens": 2048}},
            timeout=60
        )
        response.raise_for_status()
        result = response.json()
        if isinstance(result, list) and len(result) > 0:
            return result[0].get("generated_text", "")
        return str(result)
    except Exception as e:
        print(f"   ❌ HuggingFace Fehler: {e}")
        return None


def call_anthropic(model: str, prompt: str) -> Optional[str]:
    """Anthropic Claude (PAID - optional)."""
    if not ANTHROPIC_KEY:
        print(f"   ⚠️  ANTHROPIC_API_KEY fehlt")
        return None

    print(f"   💎 Anthropic → {model}")
    try:
        response = requests.post(
            "https://api.anthropic.com/v1/messages",
            headers={
                "x-api-key": ANTHROPIC_KEY,
                "anthropic-version": "2023-06-01",
                "content-type": "application/json"
            },
            json={
                "model": model,
                "max_tokens": 2048,
                "messages": [{"role": "user", "content": prompt}]
            },
            timeout=30
        )
        response.raise_for_status()
        return response.json()["content"][0]["text"]
    except Exception as e:
        print(f"   ❌ Anthropic Fehler: {e}")
        return None


# ==========================================
# PROVIDER DISPATCHER
# ==========================================
PROVIDERS = {
    "ollama": call_ollama,
    "gemini": call_gemini,
    "groq": call_groq,
    "openrouter": call_openrouter,
    "huggingface": call_huggingface,
    "anthropic": call_anthropic
}


def invoke_agent(role: str, prompt: str) -> Optional[str]:
    """
    Routet einen Agenten-Call mit automatischem Fallback.

    Strategie:
    1. Versuche primary provider
    2. Bei Fehler: versuche fallback
    3. Bei beiden Fehlern: None
    """
    if role not in ROUTING_TABLE:
        print(f"❌ Unbekannte Rolle: {role}")
        return None

    config = ROUTING_TABLE[role]
    system_prompt = f"You are a {role} agent. Respond concisely and professionally.\n\n"
    full_prompt = system_prompt + prompt

    # Primary attempt
    primary_fn = PROVIDERS[config["primary"]]
    result = primary_fn(config["model"], full_prompt)

    if result:
        return result

    # Fallback
    print(f"   🔄 Fallback aktiviert...")
    fallback_fn = PROVIDERS[config["fallback"]]
    return fallback_fn(config["fallback_model"], full_prompt)


# ==========================================
# CONFIG VALIDATION
# ==========================================
def validate_config() -> Dict[str, bool]:
    """Prüft welche Provider verfügbar sind."""
    status = {
        "ollama": False,
        "gemini": bool(GEMINI_API_KEY),
        "groq": bool(GROQ_API_KEY),
        "openrouter": bool(OPENROUTER_API_KEY),
        "huggingface": bool(HF_API_KEY),
        "anthropic": bool(ANTHROPIC_KEY)
    }

    # Test Ollama
    try:
        r = requests.get(f"{OLLAMA_HOST}/api/tags", timeout=2)
        status["ollama"] = r.status_code == 200
    except Exception:
        pass

    return status


def print_provider_status() -> bool:
    """Zeigt verfügbare Provider an."""
    print("=" * 60)
    print("🔌 PROVIDER STATUS")
    print("=" * 60)

    status = validate_config()

    icons = {True: "✅", False: "❌"}
    descriptions = {
        "ollama": "Lokal (Ollama)",
        "gemini": "Google Gemini (FREE: 15 RPM, 1M tokens/day)",
        "groq": "Groq (FREE: 30 RPM, schnellste Inference)",
        "openrouter": "OpenRouter (FREE Tier)",
        "huggingface": "HuggingFace (FREE Tier)",
        "anthropic": "Anthropic Claude (PAID)"
    }

    for provider, available in status.items():
        print(f"   {icons[available]} {provider:15s} {descriptions[provider]}")

    available_count = sum(status.values())
    print(f"\n   Verfügbar: {available_count}/{len(status)}")

    if available_count == 0:
        print("\n⚠️  KEIN Provider verfügbar!")
        print("   1. Starte Ollama: ollama serve")
        print("   2. ODER trage einen FREE API Key in .env ein:")
        print("      - GEMINI_API_KEY (https://aistudio.google.com/apikey)")
        print("      - GROQ_API_KEY (https://console.groq.com/keys)")
        print("      - OPENROUTER_API_KEY (https://openrouter.ai/keys)")
        return False

    return True


# ==========================================
# TICKET ROUTING
# ==========================================
def process_ticket(ticket_type: str, description: str) -> Optional[str]:
    """
    Routet Plane/GitHub Tickets zum richtigen Agenten.
    """
    print(f"\n📋 Ticket: {ticket_type}")
    print(f"   {description[:80]}{'...' if len(description) > 80 else ''}")
    print("-" * 60)

    role_map = {
        "Epic": "PO",
        "Strategic_Vision": "PO",
        "Architecture_Blueprint": "Architect",
        "Feature": "Coder",
        "Task": "Coder",
        "Bug": "Coder",
        "Test": "Tester",
        "Code_Review": "Reviewer"
    }

    role = role_map.get(ticket_type)
    if not role:
        print(f"⚠️  Unbekannter Ticket-Typ: {ticket_type}")
        return None

    return invoke_agent(role, description)


# ==========================================
# MAIN DEMO
# ==========================================
def main():
    print("\n🏭 Agentic Factory - Multi-Provider Router")
    print("=" * 60)
    print("")

    if not print_provider_status():
        sys.exit(1)

    print("\n" + "=" * 60)
    print("🧪 DEMO RUN")
    print("=" * 60)

    # Test-Tickets (unterschiedliche Provider)
    demo_tickets = [
        ("Strategic_Vision", "Entwerfe ein Login-System mit OAuth2"),
        ("Code_Review", "def add(a, b): return a + b"),
    ]

    for ticket_type, desc in demo_tickets:
        result = process_ticket(ticket_type, desc)
        if result:
            print(f"\n📄 Output (gekürzt):")
            print(result[:300] + ("..." if len(result) > 300 else ""))
            print()
        else:
            print("❌ Keine Antwort erhalten\n")


if __name__ == "__main__":
    main()
