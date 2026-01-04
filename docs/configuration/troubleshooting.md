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
