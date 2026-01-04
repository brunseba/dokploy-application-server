# Dokploy Configuration Scripts

This repository contains scripts and documentation for configuring Dokploy with advanced features.

## Contents

### Scripts

- **`scripts/configure-traefik-ovh-dns.sh`**: Automated configuration of Traefik with OVH DNS challenge for Let's Encrypt SSL certificates
  - Validates OVH API credentials
  - Updates Traefik configuration for DNS challenge
  - Recreates container with environment variables
  - Creates automatic backups
  - Supports dry-run mode for testing

### Documentation

- **`docs/traefik-ovh-dns-setup.md`**: Comprehensive guide for configuring Traefik with OVH DNS and Let's Encrypt
  - Step-by-step OVH API setup
  - Script usage and examples
  - Troubleshooting guide
  - Security best practices
  - Wildcard certificate configuration
  - Monitoring and maintenance
- **`docs/architecture/`**: Complete TOGAF 9.2-compliant architecture documentation (21 documents)
  - Architecture vision and principles
  - Business capability model
  - Data and application models
  - Technology stack and deployment views
  - Architecture Decision Records (ADRs)
  - Implementation roadmap
  - Governance framework

## Quick Start

### 1. Install Dokploy

#### Option A: Direct Installation
```bash
curl -sSL https://dokploy.com/install.sh | sh
```

#### Option B: Manual Installation
```bash
# Download the installer script directly
curl -sSL https://dokploy.com/install.sh -o dokploy-install.sh

# Review the script (optional but recommended)
less dokploy-install.sh

# Run the installer on your Linux server
sudo bash dokploy-install.sh
```

Wait for the installation to complete and access Dokploy at `http://YOUR_SERVER_IP:3000`

### 2. Configure Traefik with OVH DNS (Optional)

If you want automatic SSL certificates with wildcard support:

```bash
# View help and options
./scripts/configure-traefik-ovh-dns.sh --help

# Test with dry-run mode first (recommended)
sudo ./scripts/configure-traefik-ovh-dns.sh \
  --email your-email@example.com \
  --app-key YOUR_APP_KEY \
  --app-secret YOUR_APP_SECRET \
  --consumer-key YOUR_CONSUMER_KEY \
  --dry-run

# Apply configuration
sudo ./scripts/configure-traefik-ovh-dns.sh \
  --email your-email@example.com \
  --app-key YOUR_APP_KEY \
  --app-secret YOUR_APP_SECRET \
  --consumer-key YOUR_CONSUMER_KEY
```

**Prerequisites:**
- OVH API credentials (get them at https://api.ovh.com/createToken/)
- Domain managed by OVH DNS
- Root access to server
- Dokploy already installed

📖 **Full setup guide:** [docs/traefik-ovh-dns-setup.md](docs/traefik-ovh-dns-setup.md)

## Features

### Dokploy Installation Script
- ✅ Automatic Docker installation
- ✅ Docker Swarm setup
- ✅ PostgreSQL 16 database
- ✅ Redis 7 cache
- ✅ Traefik v3.6.1 reverse proxy
- ✅ Proxmox LXC support
- ✅ IPv6 support

### Traefik OVH Configuration
- ✅ Automatic wildcard SSL certificates
- ✅ DNS-01 challenge (works behind firewalls)
- ✅ Let's Encrypt integration
- ✅ Staging environment for testing
- ✅ Security headers and HSTS
- ✅ Rate limiting
- ✅ HTTP/3 support
- ✅ Automatic HTTP to HTTPS redirect

## Documentation

### Traefik OVH DNS Setup Guide
Comprehensive guide for configuring Traefik with OVH DNS challenge:
- **Why DNS challenge** - Benefits and use cases
- **OVH API setup** - Step-by-step credential creation
- **Script usage** - Examples and options
- **Verification** - Testing and monitoring
- **Troubleshooting** - Common issues and solutions
- **Wildcard certificates** - Configuration guide
- **Security best practices** - Credential protection
- **Advanced configuration** - Custom resolvers, staging

📖 [Read the full guide](docs/traefik-ovh-dns-setup.md)

### Architecture Documentation
Complete TOGAF 9.2-compliant architecture documentation:
- **Phase A: Vision** - Architecture vision, stakeholders, principles
- **Phase B: Business** - Capability model, value stream mapping
- **Phase C: Data** - Data model with 17 entities and ERD
- **Phase D: Application** - Component and flow diagrams, API specs
- **Phase E: Technology** - Technology stack and deployment views
- **Phase F: Requirements** - Traceability matrix, compliance
- **Phase G: Migration** - Implementation roadmap and timeline
- **Phase H: Governance** - Governance model and decision framework

📖 [Browse architecture docs](docs/architecture/)

## Usage Examples

### Deploy a Web Application with SSL

1. **Configure your domain DNS** to point to your server

2. **Deploy with Docker Compose**:

```yaml
version: "3.8"
services:
  webapp:
    image: your-app:latest
    networks:
      - dokploy-network
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.webapp.rule=Host(`app.example.com`)"
      - "traefik.http.routers.webapp.entrypoints=websecure"
      - "traefik.http.routers.webapp.tls.certresolver=letsencrypt"
      - "traefik.http.services.webapp.loadbalancer.server.port=3000"

networks:
  dokploy-network:
    external: true
```

3. **Access your application** at `https://app.example.com`

### Multiple Services with Wildcard Certificate

```yaml
version: "3.8"
services:
  api:
    image: api:latest
    networks:
      - dokploy-network
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.api.rule=Host(`api.example.com`)"
      - "traefik.http.routers.api.entrypoints=websecure"
      - "traefik.http.routers.api.tls.certresolver=letsencrypt"
      - "traefik.http.services.api.loadbalancer.server.port=8000"
  
  frontend:
    image: frontend:latest
    networks:
      - dokploy-network
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.frontend.rule=Host(`app.example.com`)"
      - "traefik.http.routers.frontend.entrypoints=websecure"
      - "traefik.http.routers.frontend.tls.certresolver=letsencrypt"
      - "traefik.http.services.frontend.loadbalancer.server.port=80"

networks:
  dokploy-network:
    external: true
```

## System Requirements

### Operating System
- **Linux** only (Ubuntu, Debian, CentOS, etc.)
- **Not supported**: macOS, Windows

### Resources
- **RAM**: Minimum 2GB (4GB recommended)
- **Disk**: 10GB available space
- **Network**: Ports 80, 443, 3000 available

### Software
- **Docker**: Auto-installed (version 28.5.0)
- **Root access**: Required for installation

## Architecture

### Components

```
┌─────────────────────────────────────────────────────────┐
│                    Docker Swarm                          │
│  ┌────────────────────────────────────────────────────┐ │
│  │                 dokploy-network                     │ │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────────────┐ │ │
│  │  │PostgreSQL│  │  Redis   │  │      Dokploy     │ │ │
│  │  │    16    │  │    7     │  │   (Main App)     │ │ │
│  │  └──────────┘  └──────────┘  └──────────────────┘ │ │
│  │                                        │            │ │
│  │                                   Port 3000         │ │
│  └────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
                            │
         ┌──────────────────┴──────────────────┐
         │                                      │
    ┌────▼────┐                           ┌────▼────┐
    │ Traefik │ ◄──────────────────────── │   OVH   │
    │ v3.6.1  │   DNS Challenge            │   API   │
    └─────────┘                            └─────────┘
         │
    Port 80/443
         │
    ┌────▼────┐
    │  Users  │
    └─────────┘
```

## Troubleshooting

### Check Services Status

```bash
# Docker services
docker service ls

# Traefik container
docker ps | grep traefik

# View logs
docker logs dokploy-traefik
docker service logs dokploy
```

### Common Issues

#### Port Already in Use
```bash
# Check what's using the port
sudo ss -tulnp | grep ':80'

# Stop the service
sudo systemctl stop <service_name>
```

#### Certificate Issues
```bash
# Check Traefik logs
docker logs dokploy-traefik 2>&1 | grep -i "error\|certificate"

# Verify OVH credentials
docker exec dokploy-traefik env | grep OVH

# Check acme.json
docker exec dokploy-traefik cat /etc/dokploy/traefik/acme.json
```

#### Service Not Accessible
```bash
# Verify DNS resolution
dig app.example.com

# Check service labels
docker inspect <container_name> | grep -A 20 Labels

# Test connectivity
curl -v https://app.example.com
```

## Maintenance

### Update Dokploy

```bash
curl -sSL https://dokploy.com/install.sh | sh -s update
```

### Update Traefik Configuration

```bash
# Re-run the configuration script
sudo ./scripts/configure-traefik-ovh-dns.sh \
  --email your-email@example.com \
  --app-key YOUR_APP_KEY \
  --app-secret YOUR_APP_SECRET \
  --consumer-key YOUR_CONSUMER_KEY
```

### Backup

```bash
# Backup certificates
cp /etc/dokploy/traefik/acme.json /backup/

# Backup Docker volumes
docker run --rm -v dokploy-postgres:/data -v $(pwd):/backup \
  alpine tar czf /backup/postgres-backup.tar.gz -C /data .
```

## Security

### Best Practices
1. **Change default PostgreSQL password** after installation
2. **Use firewall** to restrict access (UFW, iptables)
3. **Keep systems updated** (Docker, Traefik, OS)
4. **Backup regularly** (certificates, databases, volumes)
5. **Monitor logs** for suspicious activity
6. **Use strong passwords** for all services
7. **Enable 2FA** where available

### Secure Environment Variables

```bash
# Protect OVH credentials
chmod 600 /etc/dokploy/traefik/.env
chown root:root /etc/dokploy/traefik/.env

# Protect certificate storage
chmod 600 /etc/dokploy/traefik/acme.json
```

## Monitoring

### Log Management

```bash
# Follow logs
docker logs -f dokploy-traefik

# Search logs
docker logs dokploy-traefik 2>&1 | grep "error"

# Service logs
docker service logs -f dokploy
```

### Certificate Monitoring

```bash
# Check expiration
echo | openssl s_client -connect app.example.com:443 2>/dev/null | \
  openssl x509 -noout -dates

# View certificate details
docker exec dokploy-traefik cat /etc/dokploy/traefik/acme.json | jq
```

## Contributing

Contributions are welcome! Please:
1. Test changes thoroughly
2. Update documentation
3. Follow bash scripting best practices
4. Include error handling

## Resources

### Official Links
- **Dokploy**: https://dokploy.com/
- **Traefik**: https://doc.traefik.io/traefik/
- **Docker Swarm**: https://docs.docker.com/engine/swarm/
- **Let's Encrypt**: https://letsencrypt.org/

### API Documentation
- **OVH API**: https://eu.api.ovh.com/
- **Traefik API**: https://doc.traefik.io/traefik/operations/api/

## License

These scripts are provided as-is for configuring Dokploy. Please refer to individual component licenses:
- Dokploy: Check official repository
- Traefik: MIT License
- Docker: Apache 2.0 License

## Support

### Getting Help
- Review the comprehensive documentation in `docs/`
- Check Traefik logs for error messages
- Verify DNS configuration and propagation
- Test with Let's Encrypt staging first

### Utility Commands

```bash
# View script help
./scripts/configure-traefik-ovh-dns.sh --help

# Test configuration (dry-run mode)
./scripts/configure-traefik-ovh-dns.sh --dry-run \
  --email your-email@example.com \
  --app-key YOUR_APP_KEY \
  --app-secret YOUR_APP_SECRET \
  --consumer-key YOUR_CONSUMER_KEY

# Use custom Traefik directory
./scripts/configure-traefik-ovh-dns.sh \
  --traefik-dir /custom/path \
  --email your-email@example.com \
  --app-key YOUR_APP_KEY \
  --app-secret YOUR_APP_SECRET \
  --consumer-key YOUR_CONSUMER_KEY
```

### System Status Commands

```bash
# System status
docker service ls
docker ps
docker network ls

# Logs
docker logs dokploy-traefik
docker service logs dokploy
docker service logs dokploy-postgres

# Configuration
docker exec dokploy-traefik cat /etc/traefik/traefik.yml
docker exec dokploy-traefik cat /etc/dokploy/traefik/dynamic/middlewares.yml

# Troubleshooting
docker inspect dokploy-traefik
docker exec dokploy-traefik traefik version
curl -v https://app.example.com
```

## Project Structure

```
dokploy/
├── scripts/
│   └── configure-traefik-ovh-dns.sh    # Traefik OVH DNS configuration script
├── docs/
│   ├── traefik-ovh-dns-setup.md        # Complete setup guide
│   └── architecture/                    # TOGAF 9.2 architecture docs
│       ├── 01-vision/                   # Phase A: Architecture Vision
│       ├── 02-business/                 # Phase B: Business Architecture
│       ├── 03-data/                     # Phase C: Data Architecture
│       ├── 04-application/              # Phase D: Application Architecture
│       ├── 05-technology/               # Phase E: Technology Architecture
│       ├── 06-views/                    # Architectural Views
│       ├── 07-requirements/             # Phase F: Requirements
│       ├── 08-decisions/                # ADRs
│       ├── 09-implementation/           # Phase G: Implementation
│       └── 10-governance/               # Phase H: Governance
├── inputs/                              # Configuration examples
└── README.md                            # This file
```

## Changelog

### Version 2.0.0 (2024-12-31)
- Reorganized script location to `scripts/` directory
- Updated script name to `configure-traefik-ovh-dns.sh`
- Added comprehensive Traefik OVH DNS setup guide
- Added complete TOGAF 9.2 architecture documentation (21 documents)
- Improved dry-run mode and validation
- Added backup functionality
- Enhanced error handling and logging

### Version 1.0.0
- Initial release
- Traefik OVH DNS configuration script
- Basic setup guides
- Docker service examples

---

**Note**: These scripts are designed for Linux servers running Dokploy. Always test in a staging environment before deploying to production.
