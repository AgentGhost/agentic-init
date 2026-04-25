# Master-Spec: Agentic Software Factory (Hybrid AI ALM)

Diese Spezifikation beschreibt eine hochautomatisierte Software-Fabrik für das Jahr 2026. Sie nutzt lokale GPU-Power (RX 6900 XT) für die operative Ausführung und Cloud-Intelligenz (Claude) für die strategische Steuerung.

Da dieses Dokument die "Single Source of Truth" ist, enthält es alle Skripte, Prompts und Konfigurationen direkt eingebettet.

---

## 0. Strategisches Ziel & Vision

**Ziel:** Aufbau einer souveränen Entwicklungsumgebung (Maximal 16 $/Monat Hard-Limit), die POCs lokal in Labor-Umgebungen (VMs) validiert und für den Hyperscale vorbereitet.

**Kernkonzept:** Strategic-HITL (Human-in-the-Loop). Der Mensch agiert als CEO/Visionär und steuert ausschließlich die strategische Ausrichtung der Product Owner (PO) Agents.

---

## 1. Hardware & Modell-Infrastruktur

Die RX 6900 XT (16GB VRAM) unter Windows dient als lokales Kraftwerk. Die Intelligenz wird nach Komplexität und Kosten verteilt.

### Cloud-Modelle (Strategie & Architektur)

| Rolle | Modell | Provider | Fokus |
|-------|--------|----------|-------|
| Product Owner (PO) | claude-3-5-sonnet | Anthropic | Vision-Mapping, Plane API, Backlog |
| Architect | claude-3-5-sonnet | Anthropic | IaC (Terraform), Kafka-Design |

### Lokale Modelle (Ausführung & Qualität)

| Rolle | Modell | VRAM Bedarf | Ollama Befehl |
|-------|--------|-------------|---------------|
| Coder | qwen2.5-coder:14b | ~10 GB | `ollama pull qwen2.5-coder:14b` |
| Tester/QA | llama3.1:8b | ~5 GB | `ollama pull llama3.1` |
| Reviewer | phi3:mini | ~2 GB | `ollama pull phi3` |

### GPU-Verifizierung (Windows/AMD)

```bash
ollama run phi3 "test"
ollama ps  # Muss "100% GPU" anzeigen. Falls nicht: Fallback auf LM Studio (Vulkan)
```

---

## 2. Sicherheit, API-Keys & Umgebungsvariablen

### A. Beschaffung des Anthropic API-Keys

1. Gehe auf [console.anthropic.com](https://console.anthropic.com) und erstelle einen Account.
2. Navigiere zu Settings → Billing und lade ein Startguthaben auf.
3. **Zwingend erforderlich:** Setze unter Settings → Limits ein Hard-Limit von 16 $, um Kosteneskalationen durch fehlerhafte Agenten-Loops hardwareseitig auszuschließen!
4. Generiere den Key unter API Keys.

### B. Die Sicherheits-Basis: `.gitignore` (MUSS als Erstes passieren!)

Bevor irgendeine `.env` Datei angelegt wird, muss das Git-Repository initialisiert und die `.gitignore` konfiguriert werden, um versehentliche Leaks des API-Keys zu 100% zu verhindern.

```gitignore
.env
*.log
__pycache__/
```

### C. Die `.env` Konfiguration

Erst nachdem die `.gitignore` existiert, wird die `.env`-Datei im Stammverzeichnis angelegt:

```bash
# --- Cloud Intelligenz (Anthropic) ---
ANTHROPIC_API_KEY=sk-ant-api01-xxxxxxxxxxxxxxxxx
MONTHLY_TOKEN_BUDGET=16.0

# --- Requirements Management (Plane) ---
PLANE_API_KEY=your_plane_api_token_here
PLANE_URL=http://localhost:8080

# --- Lokale Infrastruktur ---
OLLAMA_HOST=http://localhost:11434
JENKINS_URL=http://localhost:8081
JENKINS_USER=admin
JENKINS_TOKEN=your_jenkins_api_token
```

---

## 3. Infrastruktur-Setup (Lab-Umgebung)

### A. Plane (Requirements) - `docker-compose.yml`

Wird in einer lokalen Management-VM gehostet, um Epics und Issues zu verwalten.

```yaml
version: '3.8'
services:
  plane-db:
    image: postgres:15-alpine
    restart: always
  plane-redis:
    image: redis:7-alpine
    restart: always
  plane-api:
    image: makeplane/plane-backend:latest
    restart: always
  plane-web:
    image: makeplane/plane-frontend:latest
    ports:
      - "8080:3000"
    restart: always
```

### B. CI/CD & IaC

- **Jenkins:** Automatisiert den operativen Workflow (Build → Deploy → Test)
- **Terraform:** Nutzt libvirt oder proxmox Provider für lokale VMs
- **Kafka:** Lokaler Cluster via Docker für asynchrone POC-Validierung

---

## 4. Agenten-Prompts (Systemanweisungen)

Diese Prompts werden beim Initialisieren der jeweiligen Agenten als System-Kontext übergeben.

### 4.1 Product Owner (Claude-Cloud)

**Mission:** Du bist das "Business Brain" der Fabrik (Modell: Claude 3.5 Sonnet). Du nimmst vage strategische Anweisungen des CEOs entgegen und transformierst sie in ein strukturiertes Backlog in Plane.

**Aufgaben:**
- Zerlege Visionen in Epics und User Stories
- Nutze die Plane REST-API zur Ticket-Erstellung
- Definiere präzise "Definitions of Done" (DoD), die der Tester-Agent automatisiert prüfen kann

### 4.2 Architect (Claude-Cloud)

**Mission:** Du bist der System-Designer (Modell: Claude 3.5 Sonnet). Plane die Labor-Umgebung für den POC.

**Aufgaben:**
- Erstelle Terraform-Blueprints (für KVM/Libvirt) und entwirf Kafka-Topologien
- Deine Designs müssen lokal lauffähig sein, aber den Pfad zum Hyperscale (AWS/Azure) bereits in der Konfiguration vorbereiten

### 4.3 Coder (Qwen-Local)

**Mission:** Senior Fullstack Dev (Modell: Qwen2.5-Coder 14B, lokal). Du bist das Arbeitspferd der Fabrik.

**Aufgaben:**
- Implementiere Features basierend auf Plane-Tickets
- Du hast keinen Zugriff auf externe APIs
- Deine Priorität ist funktionsfähiger, fehlerfreier Code innerhalb der lokalen Laborumgebung
- Erstelle saubere Feature-Branches

### 4.4 Tester (Llama-Local)

**Mission:** QA & Last-Test Ingenieur (Modell: Llama 3.1 8B, lokal). Du bist das Sicherheitsnetz.

**Aufgaben:**
- Validiere den Code gegen die DoD des POs
- Erstelle Unit-Tests und simuliere Last auf dem Kafka-Bus (Producer/Consumer Skripte)
- Melde Bugs direkt als neues Issue in Plane

### 4.5 Reviewer (Phi3-Local)

**Mission:** Gatekeeper (Modell: Phi3 Mini, lokal). Du bist der schnellste Filter im System.

**Aufgaben:**
- Prüfe Diffs in Pre-Commit Hooks auf Syntax und Security
- Eskaliere an den Cloud-Architect, falls lokale Fixes nach 3 Versuchen scheitern
- Blockiere unsauberen Code

---

## 5. Core-Logik: Das Gatekeeper-Routing-Script (`gatekeeper.py`)

Dieses Skript ist das absolute Herzstück der Fabrik. Es liest Tickets aus Plane und stellt durch striktes Sandboxing zu 100 % sicher, dass teure Cloud-Tokens nur für die strategischen Rollen (PO, Architect) verwendet werden. Operative Aufgaben werden zwingend an die lokale RX 6900 XT (Ollama) delegiert.

```python
import os
import requests
from dotenv import load_dotenv

load_dotenv()

# ==========================================
# KONFIGURATION & SICHERHEIT
# ==========================================
ANTHROPIC_KEY = os.getenv("ANTHROPIC_API_KEY")
OLLAMA_HOST = os.getenv("OLLAMA_HOST", "http://localhost:11434")

CLOUD_AGENTS = ["PO", "Architect"]

# ==========================================
# CLOUD EXECUTION (Streng limitiert)
# ==========================================
def invoke_cloud_agent(role: str, prompt: str) -> str:
    """Nutzt den teuren Anthropic Key. Darf NUR für CLOUD_AGENTS aufgerufen werden."""
    if role not in CLOUD_AGENTS:
        raise PermissionError(f"SICHERHEITS-BLOCK: Rolle '{role}' darf keine Cloud-Tokens verbrauchen!")
    
    print(f"[CLOUD - {role}] Sende Request an Anthropic (Claude 3.5 Sonnet)...")
    headers = {
        "x-api-key": ANTHROPIC_KEY,
        "anthropic-version": "2023-06-01",
        "content-type": "application/json"
    }
    payload = {
        "model": "claude-3-5-sonnet-20240620",
        "max_tokens": 2048,
        "messages": [{"role": "user", "content": f"System-Rolle: {role}. {prompt}"}]
    }
    
    response = requests.post("https://api.anthropic.com/v1/messages", json=payload, headers=headers)
    response.raise_for_status()
    return response.json()['content'][0]['text']

# ==========================================
# LOCAL EXECUTION (Kostenlos)
# ==========================================
def invoke_local_agent(role: str, prompt: str) -> str:
    """Nutzt RX 6900 XT via Ollama. Kostet 0,00 €."""
    model_map = {
        "Coder": "qwen2.5-coder:14b",
        "Tester": "llama3.1:8b",
        "Reviewer": "phi3:mini"
    }
    model = model_map.get(role)
    if not model:
        raise ValueError(f"Unbekannte lokale Rolle: {role}")

    print(f"[LOCAL - {role}] Sende Request an Ollama ({model})...")
    payload = {
        "model": model,
        "prompt": f"System-Rolle: {role}. {prompt}",
        "stream": False
    }
    
    response = requests.post(f"{OLLAMA_HOST}/api/generate", json=payload)
    response.raise_for_status()
    return response.json()['response']

# ==========================================
# DER GATEKEEPER (Ticket Routing Logik)
# ==========================================
def process_plane_ticket(ticket_type: str, ticket_description: str):
    print(f"\n--- Verarbeite Plane Ticket (Typ: {ticket_type}) ---")
    
    if ticket_type in ["Epic", "Strategic_Vision"]:
        return invoke_cloud_agent("PO", f"Zerlege diese Vision: {ticket_description}")
        
    elif ticket_type == "Architecture_Blueprint":
        return invoke_cloud_agent("Architect", f"Erstelle IaC für: {ticket_description}")
        
    elif ticket_type in ["Feature", "Task"]:
        return invoke_local_agent("Coder", f"Implementiere Ticket: {ticket_description}")
        
    elif ticket_type == "Test":
        return invoke_local_agent("Tester", f"Schreibe Tests für: {ticket_description}")
        
    else:
        print(f"Ignoriere unbekannten Ticket-Typ: {ticket_type}")

if __name__ == "__main__":
    # Test-Aufrufe
    process_plane_ticket("Strategic_Vision", "Baue ein sicheres Login-System mit Kafka Backend.")
    process_plane_ticket("Task", "Schreibe die auth_service.js für das Login-System.")
```

---

## 6. Git Best Practices & Hooks

- **Kleine Commits:** Jede Änderung muss atomar sein
- **AI-Context:** Jede Commit-Message enthält Details zum agierenden Modell (z.B. `implemented by qwen2.5-coder`)

### Pre-Commit Hook (`.git/hooks/pre-commit`)

Muss in jedem Agenten-Repository hinterlegt sein.

```bash
#!/bin/bash
npm test || exit 1
DIFF=$(git diff --cached)
# Lokales Leichtgewicht-Review (kostenlos)
ollama run phi3 "Review this diff briefly: $DIFF"
exit 0
```

---

## 7. Implementierungs-Roadmap

### Phase 1 (Kraftwerk)

Ollama installieren, Modelle laden (`qwen2.5-coder:14b`, `llama3.1`, `phi3`), GPU-Support prüfen.

### Phase 2 (Kommandozentrale & Security)

1. Führe `git init` aus
2. Lege zwingend zuerst die `.gitignore` an
3. Lege danach die `.env` Datei an und setze das Anthropic-Limit auf 16 $
4. Starte Plane via `docker-compose.yml` (siehe Abschnitt 3) in der Management-VM

### Phase 3 (Werkstatt)

Jenkins installieren, Git-Hooks einrichten.

### Phase 4 (Integration)

Das `gatekeeper.py` Script (siehe Abschnitt 5) als Dienst starten. Es überwacht fortan Plane.

### Phase 5 (Go-Live)

Eine Vision in Plane posten und die automatisierte Fabrik arbeiten lassen.