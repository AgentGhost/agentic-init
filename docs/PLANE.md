# Plane Usage

## Views & Components

**Naming Convention:** `{component}-{function}`
- `plane-ui` - Plane user interface
- `plane-db` - Plane database/config
- `plane-workflow` - Plane automation/workflow
- `kafka-db` - Kafka data storage
- `docker-service` - Docker service config
- `gatekeeper-agent` - Agent execution
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

## Cycles (Phases)

| Cycle | Phase | Focus |
|-------|-------|-------|
| Phase 1 | Kraftwerk | Ollama, GPU |
| Phase 2 | BUero | Git, config |
| Phase 3 | FliesSbander | Kafka, Worker |
| Phase 4 | Integration | Docker, SEC |
| Phase 5 | Go-Live | Monitoring |

## Modules (Use Cases)

In Plane UI: Project → Modules. These are **processual workflows**:

| Module | Process |
|--------|---------|
| `[UC] Ticket Processing` | Backlog → Todo → In Progress → Done |
| `[UC] Zen-Swarm Execution` | Research → Write → Critic (3x) |
| `[UC] Event-Driven Architecture` | Kafka topics, events |
| `[UC] CI/CD Pipeline` | GitHub → Jenkins → Docker |
| `[UC] Monitoring & Alerts` | Prometheus + Grafana |

**View filter:** `module = "[UC] Ticket Processing"` etc.