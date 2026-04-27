# Master-Spec: Agentic Software Factory (Hybrid AI ALM)

> **⚠️ TEMPLATE REFERENCE PROJECT**  
> Copy and adapt to your needs. This is a reference implementation, not a production-ready system.

---

Diese Spezifikation beschreibt eine hochautomatisierte Software-Fabrik für das Jahr 2026. Sie nutzt lokale GPU-Power (RX 6900 XT) für die operative Ausführung und Cloud-Intelligenz (Claude/MiniMax) für die strategische Steuerung und lokale Zen-Schwärme für fehlerfreien Code.

Da dieses Dokument die "Single Source of Truth" ist, enthält es alle Skripte, Prompts und Konfigurationen direkt eingebettet.

---

## 0. Projekt-Struktur

```
agentic-init/                 # Root
├── dev/                     # Development
│   ├── gatekeeper.py        # Core router & Swarm Orchestrator
│   ├── inbox_poller.py      # Plane poller
│   ├── swarm_ctrl.py        # Zen-Swarm CLI Trigger
│   ├── worker.py            # Kafka executor
│   ├── init-ai.sh          # Ollama setup
│   ├── Jenkinsfile         # CI/CD pipeline
│   ├── hooks/             # Git hooks
│   └── Skills/             # Agent skills
│
├── ops/                    # Operations
│   ├── docker-compose.yml # Plane + Kafka (KRaft) + Jenkins
│   ├── start-factory.sh   # Start script
│   ├── kafka-topics.sh    # Topic creation
│   ├── terraform/        # IaC (Hetzner / Libvirt)
│   ├── plane/           # Plane config + data
│   ├── certs/           # TLS certs
│   ├── monitoring/      # Prometheus/Grafana
│   └── docker/head/     # Head container Dockerfile
│
├── sec/                    # Security
│   ├── config/           # models.yaml, template.yaml
│   ├── .env             # API keys (gitignored)
│   └── .env.example     # Template
│
├── docs/                   # Documentation
├── compliance/            # Compliance logs
├── SPEC.md                # THIS FILE
└── README.md             # Quick start
```

**Trennung nach Verantwortung:**
| Ordner | Owner | Zweck |
|--------|-------|-------|
| `dev/` | Dev | Code, Testing, CI, Swarm-Logik |
| `ops/` | Ops | Deployment, Infra (WSL2 Docker) |
| `sec/` | Sec | Config, Keys |
| `docs/` | Alle | Dokumentation |

---

## 0b. Architektur: Kopf & Körper

```
┌─────────────────────────────────────────────────────────────┐
│                    WSL 2 (Ubuntu) - KOPF                     │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────────┐   │
│  │  Plane   │ │ Jenkins  │ │  Kafka   │ │ Claude API  │   │
│  │  (PM)    │ │  (CI/CD) │ │  (Bus)   │ │ (Cloud-AI)  │   │
│  └──────────┘ └──────────┘ └──────────┘ └──────────────┘   │
│                         ┌──────────────┐                     │
│                         │  head docker  │                     │
│                         │ inbox_poller  │                     │
│                         │ gatekeeper    │                     │
│                         │ swarm_ctrl    │                     │
│                         └──────────────┘                     │
└─────────────────────────────────────────────────────────────┘
                             │ │
               host.docker.internal:11434
                             │ │
┌─────────────────────────────────────────────────────────────┐
│                    Windows Host - KÖRPER                     │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────────┐   │
│  │   RX     │ │  Ollama  │ │ VS Code   │ │   Cursor     │   │
│  │ 6900 XT  │ │ (Local)  │ │   IDE     │ │    IDE       │   │
│  │  (GPU)   │ │ (Model)  │ │Continue  │ │  Continue    │   │
│  └──────────┘ └──────────┘ └──────────┘ └──────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

**WSL 2 (Head):** Plane, Jenkins, Kafka, Claude API, gatekeeper (via head container)
**Windows Host (Body):** RX 6900 XT GPU, Ollama, IDEs mit Continue Extension

---

## 0. Strategisches Ziel & Vision

**Ziel:** Aufbau einer souveränen Entwicklungsumgebung, die POCs lokal in Labor-Umgebungen (VMs) validiert und für den Hyperscale vorbereitet.

**Kernkonzept:** Strategic-HITL (Human-in-the-Loop). Der Mensch agiert als CEO/Visionär und steuert ausschließlich die strategische Ausrichtung der Product Owner (PO) Agents. Die Ausführung wird durch Zen-Schwärme (Sub-Agenten) atomisiert und automatisiert.

---

## 1. Hardware & Modell-Infrastruktur

Die RX 6900 XT (16GB VRAM) unter Windows dient als lokales Kraftwerk. Die Intelligenz wird nach Komplexität und Kosten verteilt.

### Cloud-Modelle (Strategie, Architektur & IDE)

| Rolle | Modell | Provider | Fokus |
|-------|--------|----------|-------|
| Product Owner (PO) | claude-3-5-sonnet | Anthropic | Vision-Mapping, Plane API, Backlog |
| Architect | claude-3-5-sonnet | Anthropic | IaC (Terraform), System-Design |
| IDE Master (Chat) | MiniMax M2.5 Free | OpenCode Zen | Komplexe Logik-Fragen direkt im Editor |
| IDE Writer (Auto) | Ling 2.6 Flash | OpenCode Zen | Blitzschnelles Tab-Autocomplete |

### Lokale Modelle (Ausführung, Swarm & Qualität)

| Rolle | Modell | VRAM Bedarf | Ollama Befehl |
|-------|--------|-------------|---------------|
| Swarm Master | qwen2.5-coder:14b | ~10 GB | `ollama pull qwen2.5-coder:14b` |
| Zen-Critic / QA | llama3.1:8b | ~5 GB | `ollama pull llama3.1` |
| Sub: Writer | qwen2.5-coder:7b | ~4 GB | `ollama pull qwen2.5-coder:7b` |
| Sub: Researcher | phi3:mini | ~2 GB | `ollama pull phi3` |

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

### C. Die `.env` Konfiguration (`sec/.env`)

Diese Datei liegt ausschließlich in der WSL2-VM und wird niemals nach Windows synchronisiert.

```bash
# --- Cloud Intelligenz (Anthropic) ---
ANTHROPIC_API_KEY=sk-ant-api01-xxxxxxxxxxxxxxxxx
MONTHLY_TOKEN_BUDGET=16.0

# --- Requirements Management (Plane) ---
PLANE_API_KEY=your_plane_api_token_here
PLANE_URL=http://localhost:8080

# --- Lokale Infrastruktur ---
OLLAMA_HOST=http://host.docker.internal:11434
JENKINS_URL=http://localhost:8081
JENKINS_USER=admin
JENKINS_TOKEN=your_jenkins_api_token

# --- Web Search (Grounding) ---
TAVILY_API_KEY=your_tavily_free_tier_key

# --- IaC / Staging ---
HCLOUD_TOKEN=your_hetzner_api_token
```

---

## 3. Infrastruktur-Setup (Lab-Umgebung WSL2)

Alle administrativen Tools laufen isoliert als Docker-Container in der WSL2-Ubuntu-VM.

### A. Aktuelle Versionen (2026-04-26)

| Service | Image | Tag |
|---------|-------|-----|
| Plane | makeplane/*-commercial | v2.4.0 |
| PostgreSQL | postgres | 15.7-alpine |
| Redis/Valkey | valkey | 7.2.11-alpine |
| Jenkins | jenkins/jenkins | lts |
| Kafka | bitnami/kafka | 3.7 (KRaft-Modus) |
| Kafka UI | provectuslabs/kafka-ui | latest |
| Terraform | hashicorp/terraform | >=1.6 |

**Wichtig:** Kafka 3.7+ läuft im KRaft-Modus - Kein Zookeeper mehr erforderlich. Das vereinfacht die Architektur und verbessert die Skalierbarkeit in der VM erheblich.

### B. Zentrale `ops/docker-compose.yml`

```yaml
version: '3.8'
services:
  # --- PLANE ALM ---
  plane-db:
    image: postgres:15-alpine
    restart: always
    volumes: [plane_db_data:/var/lib/postgresql/data]
  plane-redis:
    image: redis:7-alpine
    restart: always
  plane-api:
    image: makeplane/plane-backend:latest
    restart: always
    env_file: ../sec/.env
  plane-web:
    image: makeplane/plane-frontend:latest
    ports: ["8080:3000"]
    restart: always

  # --- JENKINS CI/CD ---
  jenkins:
    image: jenkins/jenkins:lts
    ports: ["8081:8080"]
    volumes:
      - jenkins_data:/var/jenkins_home
      - /var/run/docker.sock:/var/run/docker.sock
    restart: always

  # --- KAFKA (KRaft-Modus, Zookeeper-less) ---
  kafka:
    image: bitnami/kafka:3.7
    ports: ["9092:9092"]
    environment:
      - KAFKA_CFG_NODE_ID=1
      - KAFKA_CFG_PROCESS_ROLES=controller,broker
      - KAFKA_CFG_LISTENERS=PLAINTEXT://:9092,CONTROLLER://:9093
      - KAFKA_CFG_LISTENER_SECURITY_PROTOCOL_MAP=CONTROLLER:PLAINTEXT,PLAINTEXT:PLAINTEXT
      - KAFKA_CFG_CONTROLLER_QUORUM_VOTERS=1@kafka:9093
      - KAFKA_CFG_CONTROLLER_LISTENER_NAMES=CONTROLLER
      - KAFKA_KRAFT_CLUSTER_ID=agentic-factory-cluster-id
      - ALLOW_ANONYMOUS_LOGIN=yes
    volumes:
      - kafka_data:/bitnami/kafka
    restart: always

volumes:
  plane_db_data:
  jenkins_data:
  kafka_data:
```

### C. Ports (Aktuell)

| Service | Port | URL | Läuft in |
|---------|-----|-----|---------|
| Plane Web | 80 | http://localhost | Docker |
| Plane API | intern | via Caddy | Docker |
| Kafka UI | 8085 | http://localhost:8085 | Docker |
| Jenkins | 8081 | http://localhost:8081 | Docker |
| MinIO | 9000 | http://localhost:9000 | Docker |
| Ollama | 11434 | localhost:11434 | Windows Host |

---

## 4. Agenten-Prompts & Zen-Swarm Rollen

Das System nutzt das **Zen-Swarm-Prinzip**. Aufgaben werden nicht mehr von einem einzigen Coder gelöst, sondern in Atom-Schritten von Sub-Agenten iterativ abgearbeitet, bis ein fehlerfreier Zustand ("Zen") erreicht ist.

### 4.1 Product Owner & Architect (Cloud)

**Mission:** Du bist das strategische "Business Brain" (Claude 3.5 Sonnet).

- Zerlege Visionen in Epics und User Stories via Plane REST-API.
- Entwirf IaC-Blueprints (Terraform) für Hetzner/Libvirt.

### 4.2 Swarm Master (Qwen 14B - Local)

**Mission:** Orchestrator der Ausführung. Du verteilst Plane-Tickets als asynchrone Aufgaben (via Kafka) an deine Sub-Agenten und fügst die finalen Diffs zusammen.

### 4.3 Sub: Researcher (Phi3 + Tavily - Local/API)

**Mission:** Beschaffe fehlenden Kontext. Scrape via Tavily aktuelle API-Docs und erstelle Grounding-Context für die Writer.

### 4.4 Sub: Writer (Qwen 7B - Local)

**Mission:** Atomarer Coder. Du schreibst ausschließlich minimale Code-Diffs (SEARCH/REPLACE). Kein Refactoring ohne Auftrag.

### 4.5 Sub: Zen-Critic / Tester (Llama 3.1 8B - Local)

**Mission:** Das Sicherheitsnetz. Validiere die Diffs des Writers. Melde "Code-Smell" oder Syntax-Fehler lokal zurück, damit der Writer (ohne Cloud-Kosten) korrigieren kann, bevor der Code committet wird.

---

## 5. Core-Logik: Routing & Worker-Scripts

Das Herzstück der Fabrik teilt sich in drei Haupt-Skripte im `dev/` Ordner auf.

### A. inbox_poller.py

Läuft als Hintergrundprozess in der VM.

- Pollt Plane alle 30s nach neuen Tickets.
- Routet Tickets je nach Typ an den gatekeeper.py.
- Bewegt Issue nach "Todo" oder "In Progress".

**Auto-Start:** Wird automatisch von `start-factory.sh` gestartet:
- In WSL 2: als `head` Docker Container
- Auf Windows Host: als Python-Prozess

### B. gatekeeper.py

Die strikte Routing-Firewall.

- **IF** Epic/Vision: Route an Anthropic (Claude 3.5).
- **IF** Feature/Bug: Triggere den lokalen /swarm via Kafka.

### C. swarm_ctrl.py (Der Zen-Loop)

Das Skript für den isolierten Lösungszyklus:

1. Researcher generiert Kontext.
2. Writer schreibt Diff.
3. Critic prüft Diff.
4. Bei Fehler: Zurück zu Schritt 2 (Max. 3 Iterationen).

---

## 6. IDE Integration (VS Code / Cursor auf Windows)

Für die manuelle Entwicklungsarbeit auf dem Windows-Host wird die Open-Source Extension **Continue** genutzt, konfiguriert mit "OpenCode Zen" Modellen für höchste Performance und null Kosten.

`~/.continue/config.json`:

```json
{
  "models": [
    {
      "title": "Logic (MiniMax M2.5)",
      "model": "minimax-m2.5",
      "provider": "openai",
      "apiBase": "DEIN_OPENCODE_ENDPUNKT"
    },
    {
      "title": "Local Swarm Master",
      "model": "qwen2.5-coder:14b",
      "provider": "ollama",
      "apiBase": "http://localhost:11434"
    }
  ],
  "tabAutocompleteModel": {
    "title": "Speed (Ling 2.6 Flash)",
    "model": "ling-2.6-flash",
    "provider": "openai",
    "apiBase": "DEIN_OPENCODE_ENDPUNKT"
  }
}
```

---

## 7. Git Best Practices & Hooks

- **Kleine Commits:** Jede Änderung muss atomar sein
- **AI-Context:** Jede Commit-Message enthält Details zum agierenden Modell (z.B. `implemented by qwen2.5-coder`)

### Pre-Commit Hook (`.git/hooks/pre-commit`)

```bash
#!/bin/bash
npm test || exit 1
DIFF=$(git diff --cached)
# Lokales Leichtgewicht-Review (kostenlos)
ollama run phi3 "Review this diff briefly: $DIFF"
exit 0
```

---

## 8. Implementierungs-Roadmap

Die Implementierung folgt den 5 Phasen. In Plane werden diese als **Cycles** verwaltet:

| Phase | Cycle Name | Focus | Key Issues |
|-------|-------------|-------|------------|
| Phase 1 | `Kraftwerk` | Ollama, Modelle, GPU | (manual setup) |
| Phase 2 | `BUero` | Git, .env, Docker | AGI-1,2,3,4,5 |
| Phase 3 | `FliesSbander` | Kafka-Topics, Worker | AGI-6,7,8,12 |
| Phase 4 | `Integration` | Zen-Swarm, Head-Container | AGI-11,15,17,16 |
| Phase 5 | `Go-Live` | Dashboards, CI/CD | AGI-9,10,13,14,18,19 |

### Cycle Workflow

```bash
# Im Plane UI: Views -> By Cycle
# Oder API:
GET /api/v1/workspaces/{ws}/projects/{proj}/cycles/

# Automatisch beim Start:
./ops/start-factory.sh  # -> startet inbox_poller
```

**Cycle-Fortschritt:**
- Neue Issues landen automatisch im passenden Cycle
- State-Änderung: Backlog → Todo → In Progress → Done