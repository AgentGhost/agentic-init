#!/usr/bin/env python3
"""Agentic Factory - Multi-Provider Router."""
import os
import sys
import requests
from pathlib import Path
from typing import Optional, Dict
from dotenv import load_dotenv

load_dotenv()

CONFIG_PATH = Path(__file__).parent / "config" / "models.yaml"

def load_config() -> dict:
    import yaml
    with open(CONFIG_PATH) as f:
        return yaml.safe_load(f)

CONFIG = load_config()
OLLAMA_HOST = os.getenv("OLLAMA_HOST", "http://localhost:11434")

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
GROQ_API_KEY = os.getenv("GROQ_API_KEY")
OPENROUTER_API_KEY = os.getenv("OPENROUTER_API_KEY")
HF_API_KEY = os.getenv("HF_API_KEY")
ANTHROPIC_KEY = os.getenv("ANTHROPIC_API_KEY")

def call_ollama(model: str, prompt: str) -> Optional[str]:
    print(f"   Ollama -> {model}")
    try:
        response = requests.post(
            f"{OLLAMA_HOST}/api/generate",
            json={"model": model, "prompt": prompt, "stream": False},
            timeout=120
        )
        response.raise_for_status()
        return response.json()["response"]
    except Exception as e:
        print(f"   Ollama error: {e}")
        return None

def call_gemini(model: str, prompt: str) -> Optional[str]:
    if not GEMINI_API_KEY:
        print("   GEMINI_API_KEY missing")
        return None
    print(f"   Gemini -> {model}")
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
        print(f"   Gemini error: {e}")
        return None

def call_groq(model: str, prompt: str) -> Optional[str]:
    if not GROQ_API_KEY:
        print("   GROQ_API_KEY missing")
        return None
    print(f"   Groq -> {model}")
    try:
        response = requests.post(
            "https://api.groq.com/openai/v1/chat/completions",
            headers={"Authorization": f"Bearer {GROQ_API_KEY}"},
            json={"model": model, "messages": [{"role": "user", "content": prompt}], "max_tokens": 2048},
            timeout=30
        )
        response.raise_for_status()
        return response.json()["choices"][0]["message"]["content"]
    except Exception as e:
        print(f"   Groq error: {e}")
        return None

def call_openrouter(model: str, prompt: str) -> Optional[str]:
    if not OPENROUTER_API_KEY:
        print("   OPENROUTER_API_KEY missing")
        return None
    print(f"   OpenRouter -> {model}")
    try:
        response = requests.post(
            "https://openrouter.ai/api/v1/chat/completions",
            headers={"Authorization": f"Bearer {OPENROUTER_API_KEY}", "HTTP-Referer": "https://github.com/agentic-init", "X-Title": "Agentic Factory"},
            json={"model": model, "messages": [{"role": "user", "content": prompt}], "max_tokens": 2048},
            timeout=30
        )
        response.raise_for_status()
        return response.json()["choices"][0]["message"]["content"]
    except Exception as e:
        print(f"   OpenRouter error: {e}")
        return None

def call_huggingface(model: str, prompt: str) -> Optional[str]:
    if not HF_API_KEY:
        print("   HF_API_KEY missing")
        return None
    print(f"   HuggingFace -> {model}")
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
        print(f"   HuggingFace error: {e}")
        return None

def call_anthropic(model: str, prompt: str) -> Optional[str]:
    if not ANTHROPIC_KEY:
        print("   ANTHROPIC_API_KEY missing")
        return None
    print(f"   Anthropic -> {model}")
    try:
        response = requests.post(
            "https://api.anthropic.com/v1/messages",
            headers={"x-api-key": ANTHROPIC_KEY, "anthropic-version": "2023-06-01", "content-type": "application/json"},
            json={"model": model, "max_tokens": 2048, "messages": [{"role": "user", "content": prompt}]},
            timeout=30
        )
        response.raise_for_status()
        return response.json()["content"][0]["text"]
    except Exception as e:
        print(f"   Anthropic error: {e}")
        return None

PROVIDERS = {"ollama": call_ollama, "gemini": call_gemini, "groq": call_groq, "openrouter": call_openrouter, "huggingface": call_huggingface, "anthropic": call_anthropic}

def invoke_agent(role: str, prompt: str) -> Optional[str]:
    if role not in CONFIG["roles"]:
        print(f"Unknown role: {role}")
        return None

    cfg = CONFIG["roles"][role]
    system_prompt = f"You are a {role} agent. Respond concisely and professionally.\n\n"
    full_prompt = system_prompt + prompt

    primary_fn = PROVIDERS[cfg["provider"]]
    result = primary_fn(cfg["model"], full_prompt)

    if result:
        return result

    print("   Fallback activated...")
    fallback_fn = PROVIDERS[cfg["fallback"]]
    return fallback_fn(cfg["fallback_model"], full_prompt)

def validate_config() -> Dict[str, bool]:
    status = {"ollama": False, "gemini": bool(GEMINI_API_KEY), "groq": bool(GROQ_API_KEY), "openrouter": bool(OPENROUTER_API_KEY), "huggingface": bool(HF_API_KEY), "anthropic": bool(ANTHROPIC_KEY)}
    try:
        r = requests.get(f"{OLLAMA_HOST}/api/tags", timeout=2)
        status["ollama"] = r.status_code == 200
    except Exception:
        pass
    return status

def print_provider_status() -> bool:
    print("=" * 50)
    print("Provider Status")
    print("=" * 50)
    status = validate_config()
    icons = {True: "OK", False: "X"}
    names = {"ollama": "Local (Ollama)", "gemini": "Google Gemini (FREE)", "groq": "Groq (FREE)", "openrouter": "OpenRouter (FREE)", "huggingface": "HuggingFace (FREE)", "anthropic": "Anthropic Claude (PAID)"}
    for provider, available in status.items():
        print(f"   [{icons[available]}] {provider:12} {names[provider]}")
    available_count = sum(status.values())
    print(f"\n   Available: {available_count}/{len(status)}")
    if available_count == 0:
        print("No provider available!")
        return False
    return True

def process_ticket(ticket_type: str, description: str) -> Optional[str]:
    print(f"\nTicket: {ticket_type}")
    print(f"   {description[:60]}...")
    print("-" * 40)

    role = CONFIG["ticket_routing"].get(ticket_type)
    if not role:
        print(f"Unknown ticket type: {ticket_type}")
        return None

    return invoke_agent(role, description)

def main():
    print("\nAgentic Factory - Multi-Provider Router")
    print("=" * 50)
    if not print_provider_status():
        sys.exit(1)

    print("\n" + "=" * 50)
    print("Demo Run")
    print("=" * 50)

    demo_tickets = [("Strategic_Vision", "Design a login system with OAuth2"), ("Code_Review", "def add(a, b): return a + b")]
    for ticket_type, desc in demo_tickets:
        result = process_ticket(ticket_type, desc)
        if result:
            print(f"\nOutput (truncated):")
            print(result[:200] + ("..." if len(result) > 200 else ""))
            print()
        else:
            print("No response received\n")

if __name__ == "__main__":
    main()