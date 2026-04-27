# Plane + Caddy Troubleshooting Guide

## Problem: Plane Proxy (Caddy) Crash Loop

The proxy container was crash-looping with error:
```
adapting config using caddyfile: parsing caddyfile tokens for 'acme_ca': wrong argument count or unexpected line ending after 'acme_ca'
```

### Root Causes

1. **Caddyfile syntax bug (primary)** — Image-baked Caddyfile contains `acme_ca {$CERT_ACME_CA}`. When unset/empty, Caddy receives bare `acme_ca` with no argument and refuses to start.

2. **Wrong volume mount** — docker-compose.yml mounts config to `config/`, but container reads `/etc/caddy/Caddyfile`. Container kept using broken built-in copy.

3. **Windows bind-mount path quirks** — Relative bind mounts under `${INSTALL_DIR:-./plane}` interact badly with empty defaults.

### Fixes Applied

| File | Change |
|------|--------|
| `plane/caddy/config/Caddyfile` | Line 25: `{$CERT_ACME_CA}` (bare, no `acme_ca` prefix) |
| `docker-compose.yml` | Volume: `./plane/caddy/config:/etc/caddy:ro` + named volume `plane-caddy-data:/data` |

### Phase 1: Verify On-Disk State

```bash
# 1.1 Check Caddyfile line 24
grep -n "CERT_ACME_CA" plane/caddy/config/Caddyfile

# 1.2 Verify volume mount
grep -A5 "proxy:" docker-compose.yml | grep -A3 "volumes:"

# 1.3 Check CERT_ACME_CA is empty
grep "CERT_ACME_CA=" .env
```

### Phase 2: Recreate Proxy Container

```bash
# 2.1 Remove stale container
docker rm -f agentic-init-proxy-1

# 2.2 Remove old data dir (NOT config!)
rm -rf plane/caddy/data

# 2.3 Recreate
docker-compose up -d --force-recreate proxy
```

### Phase 3: Verification

```bash
# 3.1 Check status
docker ps --filter name=proxy

# 3.2 Check logs
docker logs agentic-init-proxy-1 --tail 30

# 3.3 Verify mounted Caddyfile
docker exec agentic-init-proxy-1 head -30 /etc/caddy/Caddyfile

# 3.4 HTTP test
curl -I http://localhost/

# 3.5 API test
curl -I http://localhost/api/v1/instances/
```

### Phase 4: Optional Follow-ups

- **HTTPS with local certs**: Use `plane/certs/localhost+1.pem` (see `plane/certs/README.md`)
- **TLS via Let's Encrypt**: Set `CERT_ACME_CA=https://acme-v02.api.letsencrypt.org/directory`
- **Disable SMTP ports** (25/465/587) if not needed to avoid host MTA collisions

### Relevant Files

- `docker-compose.yml` — proxy service (line ~492)
- `plane/caddy/config/Caddyfile` — corrected config
- `.env` — `CERT_ACME_CA=`, `CERT_EMAIL`, etc.

---

## Other Known Issues

| Issue | Status | Notes |
|-------|--------|-------|
| `space` container unhealthy | 🔴 Unresolved | Unrelated to proxy. Will surface as 502 on `/spaces/*` |
| SMTP ports | ⚠️ Potential conflict | May collide with host MTA |