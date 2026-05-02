# Plane Usage

## Views & Components

Create **Views** in Plane UI to filter by component label:

1. Project → Views → New View
2. Add filter: `label = "<component>"`

**Naming Convention:** `{component}-{function}`
- `plane-ui` - Plane user interface
- `plane-db` - Plane database/config
- `plane-workflow` - Plane automation/workflow
- `kafka-db` - Kafka data storage
- `docker-service` - Docker service config
- `gatekeeper-agent` - Agent execution
- `jenkins-pipeline` - Jenkins CI/CD
- `github-ci` - GitHub Actions

Each issue has exactly one component label (single responsibility).

## Cycles (Phases)

Set via Plane UI (Project → Cycles):

| Phase | Focus |
|-------|-------|
| Phase 1 | Ollama, GPU |
| Phase 2 | Git, config |
| Phase 3 | Kafka, Worker |
| Phase 4 | Docker, SEC |
| Phase 5 | Monitoring |

## Modules (Use Cases)

Set via Plane UI (Project → Modules). These are **processual workflows**:

| Module | Process |
|--------|---------|
| `[UC] Ticket Processing` | Backlog → Todo → In Progress → Done |
| `[UC] Zen-Swarm Execution` | Research → Write → Critic |
| `[UC] Event-Driven Architecture` | Kafka topics, events |
| `[UC] CI/CD Pipeline` | GitHub → Jenkins → Docker |
| `[UC] Monitoring & Alerts` | Prometheus + Grafana |

**View filter:** Use module field in views.