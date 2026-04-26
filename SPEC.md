# Master-Spec: Agentic Software Factory (Hybrid AI ALM)

Diese Spezifikation beschreibt eine hochautomatisierte Software-Fabrik für das Jahr 2026. Sie nutzt lokale GPU-Power (RX 6900 XT) für die operative Ausführung und Cloud-Intelligenz (Claude) für die strategische Steuerung.

Da dieses Dokument die "Single Source of Truth" ist, enthält es alle Skripte, Prompts und Konfigurationen direkt eingebettet.

---

## 0. Strategisches Ziel & Vision

**Ziel:** Aufbau einer souveränen Entwicklungsumgebung, die POCs lokal in Labor-Umgebungen (VMs) validiert und für den Hyperscale vorbereitet.

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

# --- Web Search (Grounding) ---
TAVILY_API_KEY=your_tavily_free_tier_key
```

## 2b. Optionale Cloud-Tools (POC)

### Web Search / Grounding

| Tool | Tier | Limit | Use Case |
|------|------|-------|---------|
| Tavily | Free | 1000 requests/month | Search-Grounding für Agent-Prompts |

### Kurzzeit-Hosting (POC 2-3 Tage)

| Provider | Typ | Kosten | Ideal für |
|----------|-----|--------|---------|
| Hetzner Cloud | Abo (stündlich) | ~€0,01-0,02/Stunde | Kurze POCs, 2-3 Tage Tests |

---

## 3. Infrastruktur-Setup (Lab-Umgebung)

### A. Aktuelle Versionen (2026-04-26)

| Service | Image | Tag |
|---------|-------|-----|
| Plane Proxy | artifacts.plane.so/makeplane/proxy-commercial | v2.4.0 |
| Plane API | artifacts.plane.so/makeplane/backend-commercial | v2.4.0 |
| Plane Web | artifacts.plane.so/makeplane/web-commercial | v2.4.0 |
| Plane Admin | artifacts.plane.so/makeplane/admin-commercial | v2.4.0 |
| PostgreSQL | postgres | 15.7-alpine |
| Redis/Valkey | valkey | 7.2.11-alpine |
| RabbitMQ | rabbitmq | 3.13.6-management-alpine |
| MinIO | minio | latest |
| Jenkins | jenkins/jenkins | lts |
| Kafka | apache/kafka | 3.7.0 |
| Kafka UI | provectuslabs/kafka-ui | latest |
| Terraform | hashicorp/terraform | >=1.6 |

### A2. Ports (Aktuell)

| Service | Port | URL |
|---------|-----|-----|
| Plane Web | 80 | http://localhost |
| Plane API | 8080 | http://localhost/api |
| Kafka UI | 8085 | http://localhost:8085 |
| Jenkins | 8081 | http://localhost:8081 |
| MinIO | 9000 | http://localhost:9000 |

**Wichtig:** Plane v2.4.0 Caddy proxy hat Problem mit leeren `CERT_ACME_CA` env vars. Workaround: Lege `CERT_ACME_CA=` in variables.env fest (oder leer lassen).

**Kafka 3.7+ läuft im KRaft-Modus** - Kein Zookeeper mehr erforderlich. Das vereinfacht die Architektur und verbessert die Skalierbarkeit.

**Lokale TLS-Zertifikate:** `plane/certs/localhost+1.pem` (mkcert-generiert). Nur für lokale Entwicklung - NICHT für Produktion.

**Terraform IaC:** Siehe `terraform/` Verzeichnis für Infrastructure-as-Code Grundgerüst.

### B. Plane (Requirements) - `docker-compose.yml`

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

> See `gatekeeper.py` for the routing implementation. Role-to-model mappings are defined in `config/models.yaml`.

### A. inbox_poller.py

Der Agent-Inbox-Poller. Läuft als Hintergrundprozess und:

- Pollt Plane alle 30s nach neuen Backlog-Tickets
- Routet Tickets automatisch via gatekeeper
- Schreibt AI-Response in Issue-Beschreibung
- Bewegt Issue nach "In Progress"

```bash
# Starten
python inbox_poller.py

# Oder als Service (Windows)
nssm install inbox-poller python inbox_poller.py
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