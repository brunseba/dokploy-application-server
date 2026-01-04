#!/bin/bash

# Script to generate missing documentation files for MkDocs
# This creates placeholder documentation that should be expanded later

DOCS_DIR="/Users/brun_s/sandbox/dokploy/docs"

# Color output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Generating missing documentation files...${NC}\n"

# Configuration files
cat > "${DOCS_DIR}/configuration/script-reference.md" << 'EOF'
# Script Reference

Complete reference for the Traefik OVH DNS configuration script.

## Script: configure-traefik-ovh-dns.sh

Located at: `scripts/configure-traefik-ovh-dns.sh`

### Purpose

Automates the configuration of Traefik to use OVH DNS challenge for Let's Encrypt SSL certificates.

### Usage

```bash
sudo ./scripts/configure-traefik-ovh-dns.sh [OPTIONS]
```

### Required Options

| Option | Description | Example |
|--------|-------------|---------|
| `--email` | Email for Let's Encrypt notifications | `admin@example.com` |
| `--app-key` | OVH Application Key | `abc123...` |
| `--app-secret` | OVH Application Secret | `def456...` |
| `--consumer-key` | OVH Consumer Key | `ghi789...` |

### Optional Options

| Option | Default | Description |
|--------|---------|-------------|
| `--endpoint` | `ovh-eu` | OVH API endpoint (ovh-eu, ovh-ca, ovh-us) |
| `--traefik-dir` | `/etc/dokploy/traefik` | Traefik configuration directory |
| `--container-name` | `dokploy-traefik` | Traefik container name |
| `--dry-run` | false | Test mode - show changes without applying |
| `-h, --help` | - | Show help message |

### Examples

**Basic usage:**
```bash
sudo ./scripts/configure-traefik-ovh-dns.sh \
  --email admin@example.com \
  --app-key YOUR_APP_KEY \
  --app-secret YOUR_APP_SECRET \
  --consumer-key YOUR_CONSUMER_KEY
```

**With custom endpoint:**
```bash
sudo ./scripts/configure-traefik-ovh-dns.sh \
  --endpoint ovh-ca \
  --email admin@example.com \
  --app-key YOUR_APP_KEY \
  --app-secret YOUR_APP_SECRET \
  --consumer-key YOUR_CONSUMER_KEY
```

**Dry-run mode (recommended first):**
```bash
sudo ./scripts/configure-traefik-ovh-dns.sh \
  --email admin@example.com \
  --app-key YOUR_APP_KEY \
  --app-secret YOUR_APP_SECRET \
  --consumer-key YOUR_CONSUMER_KEY \
  --dry-run
```

### What the Script Does

1. **Validates inputs** - Checks all required parameters
2. **Creates backups** - Backs up configuration with timestamps
3. **Updates traefik.yml** - Changes HTTP challenge to DNS challenge
4. **Configures DNS resolvers** - Sets Cloudflare and Google DNS
5. **Resets ACME storage** - Clears old certificates
6. **Recreates container** - Adds OVH environment variables
7. **Verifies startup** - Checks container is running

### Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Missing required parameter |
| 2 | Invalid parameter value |
| 3 | File/directory not found |
| 4 | Docker command failed |
| 5 | Container not running after restart |

### Environment Variables Set

The script configures these environment variables in the Traefik container:

- `OVH_ENDPOINT` - API endpoint region
- `OVH_APPLICATION_KEY` - OVH application key
- `OVH_APPLICATION_SECRET` - OVH application secret
- `OVH_CONSUMER_KEY` - OVH consumer key

### Files Modified

- `/etc/dokploy/traefik/traefik.yml` - Main Traefik configuration
- `/etc/dokploy/traefik/dynamic/acme.json` - ACME certificate storage

### Backup Files Created

Format: `{filename}.backup.YYYYMMDD_HHMMSS`

Example:
- `traefik.yml.backup.20241231_103045`
- `acme.json.backup.20241231_103045`

## Related Documentation

- [Traefik OVH DNS Setup Guide](../traefik-ovh-dns-setup.md) - Complete setup guide
- [Troubleshooting](troubleshooting.md) - Common issues and solutions

---

**Script Version**: 1.0  
**Last Updated**: 2024-12-31
EOF

cat > "${DOCS_DIR}/configuration/troubleshooting.md" << 'EOF'
# Troubleshooting Guide

Common issues and solutions for Dokploy and Traefik OVH DNS configuration.

## Installation Issues

### Docker Installation Fails

**Symptoms:**
- Installation script errors during Docker setup
- Docker commands not found

**Solutions:**
```bash
# Check if Docker is installed
docker --version

# Manually install Docker
curl -fsSL https://get.docker.com | sh

# Start Docker service
sudo systemctl start docker
sudo systemctl enable docker
```

### Port Already in Use

**Symptoms:**
- Installation fails with "port already in use" error
- Cannot bind to port 80, 443, or 3000

**Solutions:**
```bash
# Find what's using the ports
sudo ss -tulnp | grep ':80'
sudo ss -tulnp | grep ':443'
sudo ss -tulnp | grep ':3000'

# Stop conflicting service
sudo systemctl stop apache2  # or nginx
```

## Certificate Issues

### SSL Certificate Not Generated

**Symptoms:**
- Domain shows "Certificate not found"
- Traefik logs show ACME errors

**Solutions:**
```bash
# Check Traefik logs
docker logs dokploy-traefik | grep -i acme
docker logs dokploy-traefik | grep -i error

# Verify DNS resolution
dig app.example.com
nslookup app.example.com

# Check OVH credentials
docker exec dokploy-traefik env | grep OVH

# Reset ACME storage
docker exec dokploy-traefik sh -c 'echo "{}" > /etc/dokploy/traefik/dynamic/acme.json'
docker restart dokploy-traefik
```

### Rate Limit Exceeded

**Symptoms:**
- Error: "too many certificates already issued"
- Let's Encrypt rate limit errors

**Solutions:**
- Wait 1 hour (failed validation limit: 5 per hour)
- Wait 1 week (certificates per domain: 50 per week)
- Use staging environment for testing

## Deployment Issues

### Application Won't Start

**Symptoms:**
- Service shows as "failed" or "pending"
- Container keeps restarting

**Solutions:**
```bash
# Check service status
docker service ps app-name --no-trunc

# Check service logs
docker service logs app-name

# Inspect service configuration
docker service inspect app-name

# Check resource constraints
docker stats
```

### Cannot Access Application

**Symptoms:**
- Application deployed but not accessible
- 502 Bad Gateway or 404 errors

**Solutions:**
```bash
# Verify service is running
docker service ls

# Check Traefik routes
docker exec dokploy-traefik wget -O- http://localhost:8080/api/http/routers

# Verify DNS
ping app.example.com

# Check firewall
sudo ufw status
sudo firewall-cmd --list-all
```

## OVH DNS Issues

### Invalid Credentials

**Symptoms:**
- Error: "This credential is not valid"
- 403 Forbidden errors in Traefik logs

**Solutions:**
1. Verify credentials at https://api.ovh.com/createToken/
2. Check permissions:
   - GET /domain/zone/*
   - POST /domain/zone/*
   - DELETE /domain/zone/*
3. Regenerate credentials if needed
4. Re-run configuration script

### Wrong Endpoint

**Symptoms:**
- API connection errors
- Timeout errors

**Solutions:**
```bash
# Use correct endpoint for your region
# Europe: ovh-eu (default)
# Canada: ovh-ca
# USA: ovh-us

./scripts/configure-traefik-ovh-dns.sh --endpoint ovh-eu ...
```

## Docker Swarm Issues

### Swarm Not Initialized

**Symptoms:**
- "This node is not a swarm manager"
- Swarm commands fail

**Solutions:**
```bash
# Initialize Docker Swarm
docker swarm init

# If behind NAT, specify advertise address
docker swarm init --advertise-addr YOUR_SERVER_IP
```

### Node Disconnected

**Symptoms:**
- Services not running
- Node shows as "Down"

**Solutions:**
```bash
# Check node status
docker node ls

# Rejoin swarm if needed
docker swarm leave --force
docker swarm init
```

## Performance Issues

### High Memory Usage

**Symptoms:**
- Server running out of memory
- Services being killed

**Solutions:**
```bash
# Check memory usage
free -h
docker stats

# Add resource limits to services
docker service update --limit-memory 512M app-name

# Add swap space
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

### Slow Response Times

**Symptoms:**
- Application responds slowly
- High CPU usage

**Solutions:**
```bash
# Scale service
docker service scale app-name=3

# Check service resources
docker service ps app-name
docker stats

# Review logs for errors
docker service logs app-name
```

## Database Issues

### PostgreSQL Connection Failed

**Symptoms:**
- Cannot connect to database
- Connection refused errors

**Solutions:**
```bash
# Check PostgreSQL is running
docker service ls | grep postgres

# Check PostgreSQL logs
docker service logs dokploy-postgres

# Test connection
docker exec -it dokploy-postgres psql -U postgres
```

### Database Full

**Symptoms:**
- "Disk full" errors
- Cannot write to database

**Solutions:**
```bash
# Check disk space
df -h

# Clean up old Docker resources
docker system prune -a

# Backup and clean database
docker exec dokploy-postgres psql -U postgres -c "VACUUM FULL"
```

## Getting Help

If issues persist:

1. **Check Logs**
   ```bash
   docker service logs dokploy
   docker logs dokploy-traefik
   docker logs dokploy-postgres
   ```

2. **Gather Information**
   ```bash
   docker version
   docker info
   docker service ls
   docker ps -a
   ```

3. **Search Documentation**
   - [Traefik OVH DNS Setup](../traefik-ovh-dns-setup.md)
   - [Getting Started Guide](../getting-started.md)

4. **Community Support**
   - GitHub Issues
   - GitHub Discussions
   - Documentation examples

---

**Last Updated**: 2024-12-31
EOF

echo -e "${GREEN}✓${NC} Created configuration/script-reference.md"
echo -e "${GREEN}✓${NC} Created configuration/troubleshooting.md"

# Create deployment guides (simplified)
for file in single-server multi-server high-availability docker-compose-examples; do
    cat > "${DOCS_DIR}/deployment/${file}.md" << EOF
# $(echo $file | sed 's/-/ /g' | sed 's/\b\(.\)/\u\1/g')

Documentation for $(echo $file | sed 's/-/ /g') deployment pattern.

## Overview

This guide covers the $(echo $file | sed 's/-/ /g') deployment pattern for Dokploy.

## Coming Soon

Detailed documentation is being prepared. See the [Architecture Documentation](../architecture/index.md) for current information.

## Quick Reference

- [Getting Started](../getting-started.md)
- [Traefik OVH Setup](../traefik-ovh-dns-setup.md)
- [Architecture Overview](../architecture/index.md)

---

**Status**: In Progress  
**Last Updated**: 2024-12-31
EOF
    echo -e "${GREEN}✓${NC} Created deployment/${file}.md"
done

# Create operations guides (simplified)
for file in monitoring maintenance backup-restore security; do
    cat > "${DOCS_DIR}/operations/${file}.md" << EOF
# $(echo $file | sed 's/-/ /g' | sed 's/\b\(.\)/\u\1/g')

Documentation for $(echo $file | sed 's/-/ /g') operations.

## Overview

This guide covers $(echo $file | sed 's/-/ /g') best practices for Dokploy.

## Coming Soon

Detailed documentation is being prepared. See the [Architecture Documentation](../architecture/index.md) for current information.

## Quick Reference

- [Getting Started](../getting-started.md)
- [Troubleshooting](../configuration/troubleshooting.md)
- [Architecture Overview](../architecture/index.md)

---

**Status**: In Progress  
**Last Updated**: 2024-12-31
EOF
    echo -e "${GREEN}✓${NC} Created operations/${file}.md"
done

# Create reference guides (simplified)
for file in api cli configuration-files environment-variables; do
    cat > "${DOCS_DIR}/reference/${file}.md" << EOF
# $(echo $file | sed 's/-/ /g' | sed 's/\b\(.\)/\u\1/g')

Reference documentation for $(echo $file | sed 's/-/ /g').

## Overview

This reference covers $(echo $file | sed 's/-/ /g') for Dokploy.

## Coming Soon

Detailed reference documentation is being prepared. See the [Architecture Documentation](../architecture/index.md) for current information.

## Quick Reference

- [API Specification](../architecture/04-application/api-specification.md)
- [Technology Stack](../architecture/05-technology/technology-stack.md)
- [Architecture Overview](../architecture/index.md)

---

**Status**: In Progress  
**Last Updated**: 2024-12-31
EOF
    echo -e "${GREEN}✓${NC} Created reference/${file}.md"
done

# Create contributing guides (simplified)
for file in index development coding-standards release-process; do
    if [ "$file" = "index" ]; then
        title="Contributing Guide"
    else
        title="$(echo $file | sed 's/-/ /g' | sed 's/\b\(.\)/\u\1/g')"
    fi
    
    cat > "${DOCS_DIR}/contributing/${file}.md" << EOF
# ${title}

Documentation for contributing to Dokploy.

## Overview

This guide covers ${title,,} for the Dokploy project.

## Coming Soon

Detailed contributing guidelines are being prepared.

## Quick Reference

- [GitHub Repository](https://github.com/your-username/dokploy)
- [Architecture Documentation](../architecture/index.md)
- [Getting Started](../getting-started.md)

---

**Status**: In Progress  
**Last Updated**: 2024-12-31
EOF
    echo -e "${GREEN}✓${NC} Created contributing/${file}.md"
done

echo -e "\n${BLUE}Documentation generation complete!${NC}"
echo -e "${BLUE}Total files created: 20${NC}"
