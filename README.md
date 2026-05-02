# 🏭 Agentic Software Factory

**Template Reference Project** - Copy and adapt to your needs.

> **AI-Assisted Setup**: This project was initially generated using **MiniMax M2.5 Free** via **Zen** in **Opencode**. The AI helped scaffold the docker-compose, scripts, and documentation.

---

## Quick Start

```bash
# 0. Requirements
# - Python 3.10+ (miniconda recommended: C:\Users\Michael\miniconda3\python.exe)
# - Docker Desktop
# - GitHub CLI (gh) - for PRs, issues, repo management

# 1. Clone & setup
git clone <your-repo>
cd agentic-init
cp sec/.env.example sec/.env

# 2. Start infrastructure (in WSL or Docker host)
cd ops && ./start-factory.sh

# OR on Windows (use PowerShell script):
powershell -ExecutionPolicy Bypass -File "ops/start-docker.ps1"

# The start-docker.ps1 script:
# 1. Checks if Docker Desktop is running
# 2. Starts Docker Desktop if not (C:\Program Files\Docker\Docker\Docker Desktop.exe)
# 3. Waits 15 seconds for Docker to initialize
# 4. Runs docker-compose up -d

# 3. Run inbox_poller (auto-started by start-factory.sh)
# or manually: cd dev && python inbox_poller.py
```

## New Session / Restart

To restore context in a new session:

```bash
# Read these 3 files (critical)
cat SPEC.md              # Master spec + phases + architecture
cat sec/.env             # API keys + config
cat sec/config/models.yaml # Role → Model mappings

# Or quick check:
python dev/gatekeeper.py --test-fallback
```

## Architecture

```
WSL 2 (Head)                 Windows Host (Body)
┌─────────────┐             ┌─────────────┐
│  Plane      │             │  RX 6900 XT │
│  Kafka      │◄──Kafka────│  Ollama    │
│  Jenkins   │             │  IDE       │
│  head container         │
└─────────────┘             └─────────────┘
```

**Zen-Swarm Loop:** Research → Writer → Critic (max 3 iters)

## Services

| Service | URL | Port |
|---------|-----|------|
| Plane Web | http://localhost | 80/443 |
| Kafka UI | http://localhost:8085 |
| Kafka | localhost | 9092 |
| Jenkins | http://localhost:8081 |
| MinIO | http://localhost:9000 |

## Docker Troubleshooting

### docker-compose.yml syntax errors
If you get `additional properties 'xxx' not allowed` errors:
- Check that services are defined inside the `services:` block (after line 212)
- NOT after `volumes:` or `networks:` blocks at the end of the file
- Validate with: `docker-compose config -q`

### Docker Desktop not running
On Windows, run:
```powershell
powershell -ExecutionPolicy Bypass -File "ops/start-docker.ps1"
```

Or manually start Docker Desktop, wait 15s, then run `docker-compose up -d` in `ops/`.

## Project Structure

```
agentic-init/
├── dev/                     # Code (gatekeeper, inbox_poller, worker, swarm_ctrl)
├── ops/                     # Docker, scripts, plane data
├── sec/                     # Config + keys (models.yaml, .env)
├── docs/                    # Documentation
├── SPEC.md                  # Master spec (READ THIS)
└── README.md               # This file
```

## Key Files for Context Restore

| File | What It Contains |
|------|-----------------|
| `SPEC.md` | Phases, roles, Zen-Swarm, architecture |
| `sec/.env` | API keys, endpoints |
| `sec/config/models.yaml` | Role→model routing |
| `dev/gatekeeper.py` | Multi-provider router logic |
| `dev/inbox_poller.py` | Plane→Zen-Swarm connector |
| `dev/swarm_ctrl.py` | Research→Write→Critic loop |
| `ops/docker-compose.yml` | Infrastructure stack |
| `Plane (web)` | Issues, cycles, modules |

**Python 3.10+ required** (miniconda recommended)

## Plane Views & Components

**Naming Convention:** `{component}-{function}`
- `plane-ui` - Plane user interface
- `plane-db` - Plane database/config
- `plane-workflow` - Plane automation/workflow
- `plane-docs` - Plane documentation
- `kafka-db` - Kafka data storage
- `docker-service` - Docker service config
- `docker-db` - Docker data volumes
- `gatekeeper-agent` - Agent execution
- `gatekeeper-service` - Gatekeeper API
- `gatekeeper-workflow` - Gatekeeper automation
- `jenkins-pipeline` - Jenkins CI/CD
- `github-ci` - GitHub Actions

Create **Views** in Plane UI to filter by component label:

1. Project → Views → New View
2. Add filter: `label = "<component>"`

| View Name | Filter |
|-----------|--------|
| Gatekeeper | `label contains "gatekeeper"` |
| Kafka | `label contains "kafka"` |
| Jenkins | `label contains "jenkins"` |
| Docker | `label contains "docker"` |
| Plane | `label contains "plane"` |
| GitHub | `label contains "github"` |

Each issue has exactly one component label (single responsibility).

## Cycles (SPEC Phases)

| Cycle | Phase | Focus | Issues |
|-------|-------|-------|--------|
| Phase 1 | Kraftwerk | Ollama, GPU | (manual) |
| Phase 2 | BUero | Git, config | AGI-1,2,3,4,5 |
| Phase 3 | FliesSbander | Kafka, Worker | AGI-6,7,8,12 |
| Phase 4 | Integration | Docker, SEC | AGI-9,10,11,16,17 |
| Phase 5 | Go-Live | Monitoring | AGI-13,14,18,19 |

## Processual Use Cases (Modules)

In Plane UI: Project → Modules. Instead of "epics", these are **processual workflows**:

| Module | Process | Key Issues |
|-------|---------|------------|
| `[UC] Ticket Processing` | Backlog → Todo → In Progress → Done | AGI-1,2,3,4,5,17 |
| `[UC] Zen-Swarm Execution` | Research → Write → Critic (3x) | AGI-6,7,15 |
| `[UC] Event-Driven Architecture` | Kafka topics, events | AGI-8,12 |
| `[UC] CI/CD Pipeline` | GitHub → Jenkins → Docker | AGI-9,10,11 |
| `[UC] Monitoring & Alerts` | Prometheus + Grafana | AGI-13,14,16,18,19 |

**View filter:** `module = "[UC] Ticket Processing"` etc.

---

MIT 2026