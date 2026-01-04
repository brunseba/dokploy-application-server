# Dokploy Configuration & Architecture Documentation

Welcome to the comprehensive documentation for Dokploy configuration scripts and architecture.

## What is Dokploy?

Dokploy is a self-hosted Platform-as-a-Service (PaaS) that simplifies application deployment and management using Docker Swarm. It provides a user-friendly interface for deploying applications, managing databases, configuring domains, and monitoring infrastructure.

## Documentation Overview

This documentation provides:

- **Configuration Guides** - Step-by-step setup instructions for Traefik with OVH DNS and Let's Encrypt
- **Architecture Documentation** - Complete TOGAF 9.2-compliant enterprise architecture (21 documents)
- **Deployment Guides** - Single-server, multi-server, and high-availability deployment patterns
- **Operations Guides** - Monitoring, maintenance, backup/restore, and security best practices
- **API Reference** - Complete REST API documentation with examples

## Quick Links

### Getting Started
- [Quick Start Guide](quick-start.md) - Get Dokploy running in minutes
- [Traefik OVH DNS Setup](traefik-ovh-dns-setup.md) - Configure automatic SSL certificates

### Architecture
- [Architecture Overview](architecture/index.md) - High-level architecture introduction
- [Data Model](architecture/03-data/data-model.md) - Complete data model with 17 entities
- [API Specification](architecture/04-application/api-specification.md) - REST API documentation
- [Technology Stack](architecture/05-technology/technology-stack.md) - Technology choices and versions

### Operations
- [Monitoring](operations/monitoring.md) - Monitor your Dokploy installation
- [Security Best Practices](operations/security.md) - Secure your deployment
- [Backup & Restore](operations/backup-restore.md) - Protect your data

## Key Features

### Dokploy Platform
- ✅ **Easy Deployment** - Deploy applications with Git, Docker, or Compose
- ✅ **Database Management** - PostgreSQL, MySQL, MongoDB, Redis support
- ✅ **Domain Management** - Automatic SSL certificates via Let's Encrypt
- ✅ **Monitoring** - Built-in metrics and logging
- ✅ **Team Management** - RBAC with teams and permissions
- ✅ **Multi-tenant** - Isolate projects and resources

### Traefik OVH DNS Configuration
- ✅ **Automatic Wildcard Certificates** - Support for *.example.com
- ✅ **DNS-01 Challenge** - Works behind firewalls
- ✅ **Backup & Rollback** - Safe configuration changes
- ✅ **Dry-Run Mode** - Test before applying
- ✅ **HTTP/3 Support** - Modern protocol support

## Architecture Highlights

### Technology Stack
- **Orchestration**: Docker Swarm
- **Frontend**: Next.js 14 with App Router, Material UI
- **Backend**: Node.js API routes, Prisma ORM
- **Database**: PostgreSQL 16 with JSONB, Row Level Security
- **Cache**: Redis 7 with BullMQ job queue
- **Reverse Proxy**: Traefik 3.6.1 with Let's Encrypt
- **Authentication**: JWT + OIDC support

### Deployment Patterns
- **Single Server**: All-in-one deployment (2GB+ RAM)
- **Multi-Server**: Distributed deployment for scalability
- **High Availability**: 3-node cluster with automatic failover

### Security
- **5 Security Zones**: DMZ, Application, Data, Management, External
- **RBAC**: Role-based access control with Kubernetes RBAC integration
- **Encryption**: AES-256-GCM at rest, TLS 1.3 in transit
- **Compliance**: OWASP Top 10, CIS Docker Benchmark, GDPR, SOC 2

## Navigation Structure

```
📚 Documentation
│
├── 🏠 Home
│   ├── Getting Started
│   └── Quick Start
│
├── ⚙️ Configuration
│   ├── Traefik OVH DNS Setup
│   ├── Script Reference
│   └── Troubleshooting
│
├── 🏗️ Architecture (TOGAF 9.2)
│   ├── Phase A: Vision
│   ├── Phase B: Business
│   ├── Phase C: Data
│   ├── Phase D: Application
│   ├── Phase E: Technology
│   ├── Phase F: Requirements
│   ├── Phase G: Migration
│   ├── Phase H: Governance
│   └── Architecture Decisions (ADRs)
│
├── 🚀 Deployment
│   ├── Single Server
│   ├── Multi Server
│   ├── High Availability
│   └── Docker Compose Examples
│
├── 🔧 Operations
│   ├── Monitoring
│   ├── Maintenance
│   ├── Backup & Restore
│   └── Security Best Practices
│
├── 📖 Reference
│   ├── API Reference
│   ├── CLI Commands
│   ├── Configuration Files
│   └── Environment Variables
│
└── 🤝 Contributing
    ├── Contributing Guide
    ├── Development Setup
    ├── Coding Standards
    └── Release Process
```

## System Requirements

### Operating System
- **Linux only** (Ubuntu 20.04+, Debian 11+, CentOS 8+)
- **Not supported**: macOS, Windows

### Hardware
- **RAM**: Minimum 2GB (4GB recommended for production)
- **CPU**: 2 cores minimum (4+ recommended)
- **Disk**: 10GB+ available space
- **Network**: Ports 80, 443, 3000 accessible

### Software
- **Docker**: 28.5.0+ (auto-installed)
- **Docker Swarm**: Initialized during setup
- **Root access**: Required for installation

## Installation

### Quick Install

```bash
# Install Dokploy
curl -sSL https://dokploy.com/install.sh | sh

# Access at http://YOUR_SERVER_IP:3000
```

### Configure SSL with OVH DNS

```bash
# Get OVH API credentials from https://api.ovh.com/createToken/

# Test configuration (dry-run)
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

## Support & Community

### Getting Help
- 📖 Read the [comprehensive documentation](traefik-ovh-dns-setup.md)
- 🐛 Check [troubleshooting guide](configuration/troubleshooting.md)
- 💬 Ask questions in GitHub Discussions
- 🔍 Search existing GitHub Issues

### Contributing
We welcome contributions! Please see the [Contributing Guide](contributing/index.md) for:
- Development setup
- Coding standards
- Pull request process
- Release procedures

## License

These configuration scripts and documentation are provided as-is for configuring Dokploy. Please refer to individual component licenses:
- **Dokploy**: Check official repository
- **Traefik**: MIT License
- **Docker**: Apache 2.0 License

## Resources

### Official Links
- **Dokploy**: [https://dokploy.com/](https://dokploy.com/)
- **Traefik**: [https://doc.traefik.io/](https://doc.traefik.io/)
- **Docker Swarm**: [https://docs.docker.com/engine/swarm/](https://docs.docker.com/engine/swarm/)
- **Let's Encrypt**: [https://letsencrypt.org/](https://letsencrypt.org/)

### API Documentation
- **OVH API**: [https://eu.api.ovh.com/](https://eu.api.ovh.com/)
- **Traefik API**: [https://doc.traefik.io/traefik/operations/api/](https://doc.traefik.io/traefik/operations/api/)

---

**Version**: 2.0.0  
**Last Updated**: 2024-12-31  
**Status**: Production Ready
