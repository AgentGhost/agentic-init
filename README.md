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
cat docs/SPEC.md         # Master spec + phases + architecture
cat sec/.env             # API keys + config

# Plane API key is stored in sec/.env (PLANE_API_KEY)
# API interacts via Caddy proxy at localhost:80/api/v1/
# Note: If Plane returns 403/404, check proxy logs and workspace name
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
| Mail Server (SMTP) | localhost | 2025 |
| Mail Server (IMAP) | localhost | 2143 |

## Mail Server

The project includes **docker-mailserver** for agent email accounts.

### Start mail server

```bash
cd ops
docker-compose --env-file ../sec/.env up -d mail
```

### Add agent accounts

```bash
# Add mail accounts (run after starting mail container)
docker exec agentic-mail setup email add agent@factory.local --password changeme
docker exec agentic-mail setup email add po@factory.local --password changeme
docker exec agentic-mail setup email add architect@factory.local --password changeme
docker exec agentic-mail setup email add swarm@factory.local --password changeme
docker exec agentic-mail setup email add researcher@factory.local --password changeme
docker exec agentic-mail setup email add writer@factory.local --password changeme
docker exec agentic-mail setup email add critic@factory.local --password changeme
```

### Mail volumes

- Mail storage: `./ops/plane/data/mail` (on host)
- Mail state: Docker volume `agentic-init-ops_mail-state`
- Logs: Docker volume `agentic-init-ops_mail-logs`

### Ports (non-standard to avoid conflicts)

- 2025 → SMTP
- 2143 → IMAP
- 2587 → Submission
- 2993 → IMAPS

### Configuration

Edit `sec/mail.env` for mail server settings (copy from `sec/mail.env.example`):

```
DOMAINNAME=factory.local
HOSTNAME=mail.factory.local
SSL_TYPE=          # Empty = no SSL (for local dev)
ENABLE_SPAMASSASSIN=0
ENABLE_CLAMAV=0
ENABLE_FAIL2BAN=0
```

## Backup & Restore

```bash
# Backup Plane project to ops/backups/
python ops/scripts/backup_plane.py

# Restore from backup (requires Plane API access)
python ops/scripts/restore_plane.py ops/backups/<backup_file>.json
```

## One-Time Jobs

The `migrator` service runs DB migrations once, then exits. Disable after initial setup:

```bash
# First time only (after fresh DB):
MIGRATOR_REPLICAS=1 docker-compose up -d migrator

# Normal startup (migrator disabled):
docker-compose --env-file ../sec/.env up -d
```

**IMPORTANT:** Set `MIGRATOR_REPLICAS=0` in `sec/.env` after first run to avoid re-running migrations.

### When to run migrations:

1. **First-time setup** - Deploying Plane for the first time
2. **Version upgrade** - Upgrading Plane (e.g., v2.3 → v2.4)
3. **Fresh DB** - After deleting `plane-db` volume or `ops/plane/data/db/`

### Run migrations:

```bash
# Enable migrator temporarily
MIGRATOR_REPLICAS=1 docker-compose --env-file ../sec/.env up -d migrator

# Wait for completion, then disable
# (sec/.env should have MIGRATOR_REPLICAS=0)

### Pre-conditions:
- Postgres must be running: `docker ps agentic-init-ops-plane-db-1`
- Redis must be running: `docker ps agentic-init-ops-plane-redis-1`
- RabbitMQ must be running: `docker ps agentic-init-ops-plane-mq-1`

### Post-conditions:
- Check success: `docker logs agentic-init-ops-migrator-1` ends with "OK"
- API should respond: `curl localhost/api/v1/users/me/`

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

See **docs/SPEC.md** for full documentation.

See **docs/HARDWARE.md** for hardware requirements.

See **docs/TICKETS.md** for ticket type system (INITIATIVE, EPIC, STORY, BUG, TASK, FINDING).

Example hierarchy:
```
[INITIATIVE] Software Factory
  └── [EPIC] Core Development
        └── [STORY] Login flow
              └── [FINDING] API timeout
                    ├── [BUG] Fix timeout handling
                    └── [STORY] Add retry logic (improvement)
```

## Environment Management

Use tfvars for environment-specific configuration:

```
sec/env/
  defaults.tfvars    # shared non-sensitive (committed)
  dev.tfvars       # dev overrides (gitignored)
  uat.tfvars      # uat overrides (gitignored)
  prod.tfvars     # prod overrides (gitignored)
```

**GitHub Actions workflow** selects environment via dropdown (dev/uat/prod):
- Loads secrets from repo Settings → Secrets and variables → Actions
- tfvars files reference secrets as empty (filled at deploy time)

```hcl
# dev.tfvars example
ANTHROPIC_API_KEY = ""  # filled from GH Secrets
```

## Plane Cleanup Scripts

SQL scripts in `ops/cleanup/` for managing Plane project issues:

```
ops/cleanup/
  review-items.sql       # List type prefixes to identify stray items
  remove-stray-items.sql  # Template for soft-deleting stray items
  remove-duplicates.sql  # Remove duplicate INITIATIVEs/EPICs
```

**⚠️ Caution:** These scripts modify the database directly. Always:
1. Run SELECT first to preview what will be affected
2. Backup or test on non-production first
3. Use soft DELETE (deleted_at) before hard DELETE

```sql
-- Preview first
SELECT * FROM issues WHERE name LIKE '[STRANGE]%';

-- Soft delete (move to trash)
UPDATE issues SET deleted_at = NOW() WHERE name LIKE '[STRANGE]%';
```

---

MIT 2026

## Project Context: The Command Center

This `agentic-init` Git project serves as the central command center for your entire Agentic Software Factory. It encompasses:

*   **Source Code and Development Assets:** All application logic, scripts, and development utilities.
*   **Infrastructure Definitions:** Docker Compose configurations (`ops/docker-compose.yml`) for managing services like Plane, Kafka, and the Hugging Face TEI Reranker.
*   **Configuration:** Key configuration files, including those for `continue.dev` (located in `~/.continue/config.yaml`), which are designed to integrate seamlessly with the tools and services defined within this project.
*   **Documentation:** Comprehensive guides and specifications for the factory's operation and architecture.

All operations, development, and infrastructure management should be considered within the context of this repository.