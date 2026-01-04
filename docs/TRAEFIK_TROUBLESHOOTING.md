# Traefik Troubleshooting Guide

## Common Errors and Solutions

### Error: "port is missing"

**Full Error:**
```
ERR error="service \"dokploy-traefik\" error: port is missing" container=dokploy-traefik-xxx providerName=swarm
```

**Cause:**
Traefik cannot determine which port to use for routing to a Docker Swarm service. This happens when:
1. Using file-based configuration (YAML) without specifying a port
2. The service doesn't have the required `traefik.http.services.<name>.loadbalancer.server.port` label

**Solution 1: Use Service Labels (Recommended)**

For Docker Swarm services, use labels instead of file-based configuration:

```bash
docker service update <service-name> \
  --label-add "traefik.enable=true" \
  --label-add "traefik.http.routers.<router-name>.rule=Host(\`domain.com\`)" \
  --label-add "traefik.http.routers.<router-name>.entrypoints=websecure" \
  --label-add "traefik.http.routers.<router-name>.tls.certresolver=letsencrypt" \
  --label-add "traefik.http.services.<service-name>.loadbalancer.server.port=3000"
```

Example for Dokploy service:
```bash
docker service update dokploy \
  --label-add "traefik.enable=true" \
  --label-add "traefik.http.routers.dokploy.rule=Host(\`app.example.com\`)" \
  --label-add "traefik.http.routers.dokploy.entrypoints=web" \
  --label-add "traefik.http.routers.dokploy.middlewares=redirect-to-https" \
  --label-add "traefik.http.routers.dokploy-secure.rule=Host(\`app.example.com\`)" \
  --label-add "traefik.http.routers.dokploy-secure.entrypoints=websecure" \
  --label-add "traefik.http.routers.dokploy-secure.tls.certresolver=letsencrypt" \
  --label-add "traefik.http.services.dokploy.loadbalancer.server.port=3000"
```

**Solution 2: Remove Problematic Dynamic Configuration**

If you have file-based configuration causing the error:

```bash
# Remove or rename the problematic file
sudo rm /etc/dokploy/traefik/dynamic/dokploy.yml
# or
sudo mv /etc/dokploy/traefik/dynamic/dokploy.yml /etc/dokploy/traefik/dynamic/dokploy.yml.bak

# Traefik will automatically reload
```

**Solution 3: Fix File-Based Configuration**

If you must use file-based configuration, ensure the service is accessible:

```yaml
http:
  services:
    my-service:
      loadBalancer:
        servers:
          - url: http://service-name:3000  # Service must be on same network
```

---

### Error: "cannot get ACME client ovh: missing authentication information"

**Full Error:**
```
ERR Unable to obtain ACME certificate for domains error="cannot get ACME client ovh: new client: missing authentication information"
```

**Cause:**
OVH DNS credentials are not configured in the Traefik container environment variables.

**Solution:**

Configure Traefik with OVH DNS credentials:

```bash
task traefik:configure
```

Or manually:
```bash
# Get OVH API credentials from: https://api.ovh.com/createToken/
./scripts/configure-traefik-ovh-dns.sh \
  --email your-email@example.com \
  --app-key YOUR_APP_KEY \
  --app-secret YOUR_APP_SECRET \
  --consumer-key YOUR_CONSUMER_KEY
```

**Temporary Workaround:**

If you don't need OVH DNS (using HTTP challenge instead), remove the DNS challenge configuration and use HTTP challenge.

---

### Error: "Certificate Not Found"

**Symptoms:**
- SSL certificate warnings in browser
- ACME errors in Traefik logs

**Solutions:**

1. **Check DNS resolution:**
```bash
dig your-domain.com
nslookup your-domain.com
```

2. **Verify domain points to server:**
```bash
curl -I http://your-domain.com
```

3. **Check Traefik logs:**
```bash
task traefik:logs:acme
```

4. **Reset ACME storage (last resort):**
```bash
# Backup first
task traefik:backup

# Reset
sudo sh -c 'echo "{}" > /etc/dokploy/traefik/dynamic/acme.json'
sudo chmod 600 /etc/dokploy/traefik/dynamic/acme.json

# Restart Traefik
task traefik:restart
```

---

### Error: "Cannot connect to Docker daemon"

**Solution:**

Ensure Docker socket is properly mounted:

```bash
# Check if socket exists
ls -l /var/run/docker.sock

# Check Traefik service mounts
docker service inspect dokploy-traefik --format='{{json .Spec.TaskTemplate.ContainerSpec.Mounts}}' | jq
```

---

### Error: "Network not found"

**Solution:**

Create the required network:

```bash
docker network create --driver overlay --attachable dokploy-network
```

---

## Diagnostic Commands

### Check Traefik Status
```bash
task traefik:status
task traefik:logs:follow
```

### Check Service Configuration
```bash
# View Traefik config
task traefik:config:show

# Check dynamic configuration files
ls -la /etc/dokploy/traefik/dynamic/

# View specific file
cat /etc/dokploy/traefik/dynamic/middlewares.yml
```

### Check Services and Networks
```bash
# List services
docker service ls

# List networks
docker network ls

# Inspect service
docker service inspect <service-name>

# Check which containers are on dokploy-network
docker network inspect dokploy-network
```

### Check ACME Certificates
```bash
# View certificate storage
sudo cat /etc/dokploy/traefik/dynamic/acme.json | jq

# Check file permissions
ls -l /etc/dokploy/traefik/dynamic/acme.json
# Should be: -rw------- (600)
```

---

## Best Practices

### 1. Use Service Labels for Swarm Services

✅ **Good - Using labels:**
```yaml
version: "3.8"
services:
  app:
    image: myapp:latest
    networks:
      - dokploy-network
    deploy:
      labels:
        - "traefik.enable=true"
        - "traefik.http.routers.app.rule=Host(`app.example.com`)"
        - "traefik.http.services.app.loadbalancer.server.port=3000"
```

❌ **Avoid - File-based config for Swarm services:**
```yaml
# This can cause "port is missing" errors
http:
  routers:
    app:
      rule: Host(`app.example.com`)
      service: app
  services:
    app:
      loadBalancer:
        servers:
          - url: http://app:3000  # May not work reliably with Swarm
```

### 2. Always Specify Port

Even if your service only exposes one port, always specify it explicitly:

```bash
--label-add "traefik.http.services.<name>.loadbalancer.server.port=3000"
```

### 3. Use Correct Networks

Ensure all services are on the same network:

```bash
docker service update <service> --network-add dokploy-network
```

### 4. Enable Service Discovery

In traefik.yml:
```yaml
providers:
  swarm:
    exposedByDefault: false  # Only expose labeled services
    watch: true              # Auto-detect changes
```

---

## Getting Help

1. **Check logs:** `task traefik:logs:follow`
2. **Verify configuration:** `task traefik:config:show`
3. **Test with dry-run:** `task traefik:configure:dry-run`
4. **Backup before changes:** `task traefik:backup`
5. **Consult documentation:** [Traefik Docs](https://doc.traefik.io/traefik/)

---

**Last Updated:** 2025-01-04  
**Traefik Version:** 3.6.1
