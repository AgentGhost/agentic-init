# Local TLS Certificates

This directory contains locally-generated TLS certificates for development/testing only.

## Files

- `localhost+1.pem` - TLS certificate
- `localhost+1-key.pem` - Private key

## Generation

Generated using mkcert:
```bash
mkcert -install
mkcert localhost
```

## Security Warning

**DO NOT USE IN PRODUCTION**

- Self-signed certificates
- Only valid for localhost
- Not publicly trusted
- For local development only

## Production Options

For production, use one of:
1. Let's Encrypt (free, requires public domain)
2. Public CA certificate
3. Your own PKI

## Current Usage

Caddy uses these certs via:
```
tls /certs/localhost+1.pem /certs/localhost+1-key.pem
```

In docker-compose.yml, the certs directory is mounted as:
```yaml
volumes:
  - ./plane/certs:/certs:ro
```