# 🏭 Agentic Software Factory

**Template Reference Project** - Copy and adapt to your needs.

> **AI-Assisted Setup**: This project was initially generated using **MiniMax M2.5 Free** via **Zen** in **Opencode**. The AI helped scaffold the docker-compose, scripts, and documentation.

---

## Commit Convention

Use [Conventional Commits](https://www.conventionalcommits.org/) and reference the work item:

```
feat(ops): add backup script

Refs: AGI-89
```

- Type: `feat`, `fix`, `docs`, `chore`, `refactor`, `test`
- Scope: `ops`, `dev`, `sec`, `readme`, etc.
- Reference: `Refs: AGI-<sequence_id>` (from Plane issue)

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

## Backup & Restore

```bash
# Backup Plane project to ops/backups/
python ops/scripts/backup_plane.py

# Restore from backup (requires Plane API access)
python ops/scripts/restore_plane.py ops/backups/<backup_file>.json
```

## One-Time Jobs

The `migrator` service runs DB migrations once on initial setup, then exits. Use for other one-time jobs:

```bash
# Run migrations (or any one-time job)
cd ops
docker-compose run --rm migrator

# Or with specific command
docker-compose run --rm migrator ./bin/docker-entrypoint-migrator.sh
```

### When to run migrations:

1. **First-time setup** - Deploying Plane for the first time
2. **Version upgrade** - Upgrading Plane (e.g., v2.3 → v2.4)
3. **Fresh DB** - After deleting `plane-db` volume
4. **Schema errors** - If API logs show DB-related errors

### Check migration status:
```bash
docker logs agentic-init-ops-migrator-1
```

## Docker Troubleshooting

### docker-compose.yml syntax errors
If you get `additional properties 'xxx' not allowed` errors:
- Check that services are defined inside the `services:` block (after line 212)
- NOT after `volumes:` or `networks:` blocks at the end of the file
- Validate with: `docker-compose config -q`

### Port conflicts (8085, 80)
If startup fails with port conflicts:
```bash
# Check what's using the port
netstat -ano | findstr ":8085"

# Remove old containers
docker rm -f $(docker ps -aq -f name="^ops-") 2>/dev/null
```

### API not responding
1. Check logs: `docker logs agentic-init-ops-api-1`
2. Check proxy: `docker logs agentic-init-ops-proxy-1`
3. Check proxy is in network: `docker network inspect agentic-net`

### Container naming issues
Always use project name to avoid duplicate containers:
```bash
# Use -p flag
docker-compose -p agentic-init-ops up -d

# Or ensure docker-compose.yml has:
name: agentic-init-ops
networks:
  default:
    name: agentic-net
```

### RabbitMQ cookie permission errors
Don't use bind mounts on Windows. Use named volumes:
```yaml
plane-mq:
  volumes:
    - rabbitmq_data:/var/lib/rabbitmq  # NOT: ./plane/data/mq:/var/lib/...
```

## Reference

See **SPEC.md** for full documentation.

See **docs/TICKETS.md** for ticket type system (EPIC, STORY, BUG, TASK, FINDING).

See **docs/PLANE.md** for Plane usage guide (views, cycles, modules).

---

MIT 2026