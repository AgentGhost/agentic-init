# 🏭 Agentic Software Factory - Hybrid AI ALM

Ein hochautomatisiertes Development-Setup für 2026: Lokale GPU-Power trifft Cloud-Intelligenz.

**Fokus:** Stabiler, kosteneffizienter AI-Dev-Agent mit hoher (kontrollierter) Autonomie.

---

## 🎯 Kern-Features

| Feature | Status | Beschreibung |
|---------|--------|-------------|
| **Lokale GPU-Kraftwerk** | ✅ | RX 6900 XT (16GB VRAM) via Ollama |
| **Multi-Agent Routing** | ✅ | Cloud für Strategie, Lokal für Ausführung |
| **Kostenkontrolle** | ✅ | Hard-Limit $16/Monat via Anthropic |
| **Gatekeeper Router** | ✅ | Intelligente Ticket-Verteilung |
| **Git Integration** | ✅ | Pre-Commit Hooks mit AI-Review |
| **Plane Integration** | 🔄 | Requirements Management via Docker |

---

## 📋 Architektur

```
┌─────────────────────────────────────────┐
│     Vision / Task (vom Menschen)       │
└────────────────┬────────────────────────┘
                 │
         ┌───────▼────────┐
         │  GATEKEEPER    │ (Router-Logik)
         └───┬────────┬───┘
             │        │
    ┌────────▼┐   ┌───▼───────┐
    │ CLOUD   │   │ LOCAL     │
    │ $$ $    │   │ FREE      │
    └────┬────┘   └───┬───────┘
         │            │
    ┌────▼────┐   ┌───▼──────────────┐
    │  PO     │   │ Coder (Qwen)     │
    │Architect│   │ Tester (Llama)   │
    │(Claude) │   │ Reviewer (Phi3)  │
    └─────────┘   └──────────────────┘
```

---

## 🚀 Schnelstart

### Phase 1: Hardware Setup

**Voraussetzung:** Windows/Linux mit GPU (RX 6900 XT oder ähnlich)

```bash
# 1. Installiere Ollama
# https://ollama.ai

# 2. Klone dieses Repo
git clone <repo-url>
cd agentic-init

# 3. Starte init-ai.sh
chmod +x init-ai.sh
./init-ai.sh
```

Die `init-ai.sh` wird automatisch:
- ✅ Ollama validieren
- ✅ Modelle pullen (deepseek-coder:6.7b, llama3:8b, phi3)
- ✅ GPU-Support testen

### Phase 2: Sicherheit & Konfiguration

```bash
# 1. Git initialisieren
git init

# 2. .gitignore ist bereits vorhanden ✅

# 3. Hole deinen Anthropic API Key
# -> https://console.anthropic.com/api/keys

# 4. Erstelle .env
cp .env.example .env
# Editiere .env und trage deinen Key ein
# WICHTIG: Setze Hard-Limit auf $16 in Anthropic Console!
```

**Sicherheits-Checkliste:**
- [ ] `.env` enthält nur lokale Kopie
- [ ] `.env` steht in `.gitignore`
- [ ] API-Key nie in Git commitet
- [ ] Hard-Limit in Anthropic Console gesetzt

### Phase 3: Plane (Requirements Management)

```bash
# Starte Plane via Docker Compose
docker-compose up -d

# Zugriff:
# - Web UI: http://localhost:8080
# - API: http://localhost:8000
```

### Phase 4: Router testen

```bash
# Starte gatekeeper.py mit Demo-Tickets
python3 gatekeeper.py
```

Beispiel-Output:
```
🏭 Agentic Software Factory - Gatekeeper Router
☁️  [CLOUD - PO] Sende Request an Anthropic...
✅ Response erhalten (1234 Zeichen)

🖥️  [LOCAL - Coder] Sende Request an Ollama (qwen2.5-coder:14b)...
✅ Response erhalten (567 Zeichen)
```

---

## 📁 Dateistruktur

```
agentic-init/
├── SPEC.md                    # Master-Spezifikation (Single Source of Truth)
├── README.md                  # Dieses Dokument
├── init-ai.sh                 # Setup-Script für lokale Modelle
├── gatekeeper.py              # Core Router (Ticket → Agent)
├── docker-compose.yml         # Plane (Requirements Management)
├── .gitignore                 # Sicherheit: .env wird nicht committed
├── .env.example               # Template für lokale Umgebung
└── hooks/
    └── pre-commit.sh          # Git Hook mit AI-Review
```

---

## 🤖 Agent-Rollen

### Cloud Agents (Teuer, Strategisch)

| Role | Model | Aufgaben |
|------|-------|----------|
| **Product Owner (PO)** | Claude 3.5 Sonnet | Vision → Epics, Backlog, DoD |
| **Architect** | Claude 3.5 Sonnet | Terraform, Kafka-Design, IaC |

**Kosten:** ~$0.003/1K Tokens → Hard-Limit $16/Monat

### Local Agents (Kostenlos, Operational)

| Role | Model | VRAM | Aufgaben |
|------|-------|------|----------|
| **Coder** | Qwen2.5-Coder 14B | ~10 GB | Feature-Implementierung |
| **Tester** | Llama3.1 8B | ~5 GB | Unit-Tests, QA |
| **Reviewer** | Phi3 Mini | ~2 GB | Code-Review, Syntax-Check |

**Kosten:** €0,00 ✅

---

## 🔐 API Keys & Kostenkontrolle

### Anthropic (Einmalige Einrichtung)

```bash
# 1. Konto erstellen
# https://console.anthropic.com

# 2. Hard-Limit setzen (ZWINGEND!)
# Settings → Billing → Limits → $16.00
# Dies verhindert Kostenausgehen bei Loop-Bugs

# 3. API Key generieren
# Settings → API Keys

# 4. In .env eintragen
ANTHROPIC_API_KEY=sk-ant-api01-xxxxxxxxxxxxx
```

### Tokens sparen

- **80-90% Tasks → Lokal** (kostenlos)
- **10-20% Tasks → Cloud** (strategisch)
- **Caching:** Häufige Prompts lokal in SQLite cachen

---

## 📊 Git Workflow

### Mit AI-Unterstützung

```bash
# 1. Feature-Branch
git checkout -b feature/my-feature

# 2. Code via Agent generieren lassen
# (Nutze gatekeeper.py oder Ollama direkt)

# 3. Pre-Commit Hook läuft automatisch
# - Syntax-Checks ✅
# - Optional: AI-Review via phi3 🤖
git add .
git commit -m "feat: my feature

Implemented by: qwen2.5-coder
Tests: unit + integration
"

# 4. Push & PR
git push origin feature/my-feature
gh pr create --title "AI: My Feature" --body "Generated with AI support"
```

### Commit-Message Format

```
feat(component): description

AI-Context:
- Model: qwen2.5-coder:14b
- Time: 2min
- Tests: ✅ 12/12 passed
```

---

## 🔄 Workflow-Beispiel: Login-System

```
1. VISION (Mensch → Cloud PO)
   "Baue sicheres Login mit OAuth2 + Kafka Event Stream"

   ↓ (Router: Strategic_Vision)

2. BREAKDOWN (PO Agent → Plane Tickets)
   Epic: User Authentication System
   - US-101: OAuth2 Provider Integration
   - US-102: JWT Token Management
   - US-103: Kafka Event Stream Setup

   ↓ (Router: Feature)

3. IMPLEMENTATION (Coder Agent → Ollama Qwen)
   "Implementiere OAuth2 Provider..."
   → auth_provider.py (267 Zeilen)

   ↓ (Router: Test)

4. TESTING (Tester Agent → Ollama Llama)
   "Schreibe Unit-Tests für OAuth2..."
   → test_auth_provider.py (156 Zeilen)

   ↓ (Pre-Commit Hook)

5. CODE REVIEW (Reviewer Agent → Ollama Phi3)
   Syntax ✅ | Security ✅ | Style ✅

   ↓

6. COMMIT & PR (Manuell freigegeben)
   ✅ Push to feature/oauth2
   ✅ GitHub PR created
```

---

## 🛠️ Troubleshooting

### Ollama findet GPU nicht

```bash
# Prüfe GPU Status
ollama ps

# Falls leer: GPU wird nicht genutzt
# Lösungen:
# 1. Windows/AMD: Erwäge LM Studio mit Vulkan Backend
# 2. Linux: Prüfe ROCm Installation
# 3. Docker: GPU-Support aktivieren
```

### Anthropic API Returns 429 (Rate Limit)

```bash
# Du hast dein $16 Limit überschritten!
# Prüfe: https://console.anthropic.com/account/usage
# Setze evtl. Hard-Limit tiefer oder warte bis Monat endet
```

### Plane Container startet nicht

```bash
# Logs anschauen
docker-compose logs plane-api

# Typisches Problem: Port 8000/8080 belegt
# Ändern in docker-compose.yml:
# ports:
#   - "8001:8000"  # Statt 8000
```

---

## 📈 Skalierung für Produktion

### Mit zusätzlichen Cloud-Features

```yaml
# Künftige Erweiterungen:
- ChromaDB: RAG (Retrieval-Augmented Generation)
- SQLite Memory: Agent-Kontext über Sessions
- LangGraph: Komplexe Multi-Agent Orchestration
- Jenkins: Automated Build & Deploy Pipeline
```

### Hyperscale-Ready

Alle Terraform-Blueprints sind bereits vorbereitet für:
- AWS (ECS, Lambda, RDS)
- Azure (AKS, Cosmos DB)
- GCP (Cloud Run, Cloud SQL)

---

## 📚 Dokumentation

| Dokument | Zweck |
|----------|-------|
| [SPEC.md](SPEC.md) | Vollständige Spezifikation (Single Source of Truth) |
| [gatekeeper.py](gatekeeper.py) | Core Router - Quellcode |
| [init-ai.sh](init-ai.sh) | Setup-Script |
| [.env.example](.env.example) | Umgebungsvariablen-Template |

---

## 📞 Support

- **Ollama Issues:** https://github.com/ollama/ollama/issues
- **Anthropic API:** https://support.anthropic.com
- **Plane Docs:** https://docs.plane.so
- **GitHub Copilot:** VS Code Chat Integrated

---

## 📄 Lizenz

MIT

---

**Made for 2026** — Ein Jahr ohne Grenzen für lokale AI Development. 🚀
