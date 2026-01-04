# Getting Started with Dokploy

This guide will help you get started with Dokploy, from installation to deploying your first application.

## What is Dokploy?

Dokploy is a self-hosted Platform-as-a-Service (PaaS) that simplifies application deployment and management using Docker Swarm. It provides:

- **Easy Deployment** - Deploy from Git, Docker images, or Docker Compose
- **Database Management** - Built-in support for PostgreSQL, MySQL, MongoDB, Redis
- **SSL Certificates** - Automatic Let's Encrypt integration via Traefik
- **Team Management** - RBAC with teams and permissions
- **Monitoring** - Built-in metrics and logging

## Prerequisites

Before installing Dokploy, ensure your system meets these requirements:

### Operating System
- **Supported**: Ubuntu 20.04+, Debian 11+, CentOS 8+, RHEL 8+
- **Not Supported**: macOS, Windows (use Linux VM or WSL2)

### Hardware Requirements
- **RAM**: 2GB minimum (4GB+ recommended)
- **CPU**: 2 cores minimum (4+ recommended)
- **Disk**: 10GB+ available space
- **Network**: Stable internet connection

### Network Requirements
Open the following ports:
- **Port 80** - HTTP traffic (Traefik)
- **Port 443** - HTTPS traffic (Traefik)
- **Port 3000** - Dokploy web UI
- **Port 2377** - Docker Swarm management (if multi-node)

### Access Requirements
- **Root or sudo access** - Required for Docker installation
- **Domain name** (optional) - For SSL certificates and custom domains

## Installation Steps

### Step 1: Install Dokploy

Run the installation script on your Linux server:

```bash
curl -sSL https://dokploy.com/install.sh | sh
```

This script will:
1. Install Docker 28.5.0
2. Initialize Docker Swarm
3. Deploy PostgreSQL 16 database
4. Deploy Redis 7 cache
5. Deploy Traefik 3.6.1 reverse proxy
6. Deploy Dokploy application

**Installation takes approximately 5-10 minutes.**

### Step 2: Access Dokploy

Once installation completes:

1. Open your browser and navigate to:
   ```
   http://YOUR_SERVER_IP:3000
   ```

2. Create your admin account:
   - Email address
   - Strong password (12+ characters)
   - Confirm password

3. You'll be redirected to the Dokploy dashboard

### Step 3: Configure Your First Project

1. **Create a Project**
   - Click "Create Project"
   - Enter project name (e.g., "My First App")
   - Add description (optional)
   - Click "Create"

2. **Add an Application**
   - Inside your project, click "Add Application"
   - Choose deployment method:
     - **Git** - Deploy from GitHub/GitLab
     - **Docker** - Deploy from Docker image
     - **Docker Compose** - Deploy multi-container app

### Step 4: Deploy Your First Application

#### Option A: Deploy from Git

```yaml
# Example: Deploy a Node.js application
Repository: https://github.com/your-username/your-app
Branch: main
Build Command: npm install && npm run build
Start Command: npm start
Port: 3000
```

#### Option B: Deploy from Docker Image

```yaml
Image: nginx:latest
Port: 80
Environment Variables:
  - NGINX_HOST=example.com
  - NGINX_PORT=80
```

#### Option C: Deploy with Docker Compose

```yaml
version: "3.8"
services:
  web:
    image: nginx:latest
    ports:
      - "80:80"
    networks:
      - dokploy-network

networks:
  dokploy-network:
    external: true
```

### Step 5: Configure Domain and SSL (Optional)

1. **Add Domain**
   - Go to your application settings
   - Click "Domains"
   - Add your domain: `app.example.com`
   - Point your DNS A record to your server IP

2. **Configure SSL**
   - Dokploy automatically requests Let's Encrypt certificates
   - Wait 1-2 minutes for certificate provisioning
   - Your app will be available at `https://app.example.com`

## Next Steps

### Configure Advanced Features

- **[Traefik OVH DNS Setup](traefik-ovh-dns-setup.md)** - Wildcard SSL certificates
- **[Database Management](operations/backup-restore.md)** - Backup and restore databases
- **[Team Management](#)** - Add team members with RBAC
- **[Monitoring](operations/monitoring.md)** - Set up metrics and alerts

### Explore Documentation

- **[Architecture](architecture/index.md)** - Understand Dokploy architecture
- **[Deployment Patterns](deployment/single-server.md)** - Advanced deployment options
- **[API Reference](reference/api.md)** - Integrate with Dokploy API
- **[Security Best Practices](operations/security.md)** - Secure your installation

### Join the Community

- **GitHub** - Star the repository and open issues
- **Documentation** - Browse comprehensive guides
- **Examples** - Check out deployment examples

## Common First-Time Setup Tasks

### 1. Change Default PostgreSQL Password

```bash
# Connect to the PostgreSQL container
docker exec -it dokploy-postgres psql -U postgres

# Change password
ALTER USER postgres WITH PASSWORD 'your_strong_password';
\q
```

### 2. Configure Firewall

```bash
# Using UFW (Ubuntu)
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 3000/tcp
sudo ufw enable

# Using firewalld (CentOS/RHEL)
sudo firewall-cmd --permanent --add-port=80/tcp
sudo firewall-cmd --permanent --add-port=443/tcp
sudo firewall-cmd --permanent --add-port=3000/tcp
sudo firewall-cmd --reload
```

### 3. Set Up Backups

```bash
# Create backup directory
mkdir -p /backup/dokploy

# Backup PostgreSQL
docker exec dokploy-postgres pg_dump -U postgres dokploy > /backup/dokploy/db-$(date +%Y%m%d).sql

# Backup Traefik certificates
cp /etc/dokploy/traefik/dynamic/acme.json /backup/dokploy/acme-$(date +%Y%m%d).json
```

### 4. Configure System Monitoring

```bash
# Check Docker service status
sudo systemctl status docker

# Check Dokploy services
docker service ls

# View logs
docker service logs dokploy
docker logs dokploy-traefik
```

## Troubleshooting

### Installation Issues

**Problem**: Installation script fails
```bash
# Check system requirements
cat /etc/os-release
free -h
df -h

# Check Docker installation
docker --version
docker ps
```

**Problem**: Cannot access Dokploy UI
```bash
# Check if Dokploy is running
docker service ls | grep dokploy

# Check Dokploy logs
docker service logs dokploy

# Check firewall
sudo ufw status
```

### Deployment Issues

**Problem**: Application fails to deploy
```bash
# Check application logs
docker service logs <service_name>

# Check Docker Swarm status
docker node ls
docker service ps <service_name>
```

**Problem**: SSL certificate not generated
```bash
# Check Traefik logs
docker logs dokploy-traefik | grep -i acme
docker logs dokploy-traefik | grep -i certificate

# Verify DNS resolution
dig app.example.com
```

For more detailed troubleshooting, see the [Troubleshooting Guide](configuration/troubleshooting.md).

## Quick Reference

### Useful Commands

```bash
# Check Dokploy version
docker exec $(docker ps -q -f name=dokploy) cat package.json | grep version

# Restart Dokploy
docker service update --force dokploy

# View all services
docker service ls

# Scale application
docker service scale app_name=3

# Update Dokploy
curl -sSL https://dokploy.com/install.sh | sh -s update
```

### Default Credentials

- **Dokploy UI**: Set during first access
- **PostgreSQL**: `postgres` / Check Docker Swarm secrets
- **Redis**: No password by default (change recommended)

### Important Paths

- **Dokploy Config**: `/etc/dokploy/`
- **Traefik Config**: `/etc/dokploy/traefik/`
- **SSL Certificates**: `/etc/dokploy/traefik/dynamic/acme.json`
- **Docker Volumes**: `/var/lib/docker/volumes/`

## Getting Help

If you encounter issues:

1. Check the [Troubleshooting Guide](configuration/troubleshooting.md)
2. Review [Dokploy logs](#useful-commands)
3. Search [GitHub Issues](https://github.com/your-username/dokploy/issues)
4. Ask in GitHub Discussions

## What's Next?

Now that you have Dokploy running:

1. **Deploy More Applications** - Try different deployment methods
2. **Configure Monitoring** - Set up metrics and alerting
3. **Add Team Members** - Invite collaborators
4. **Set Up Backups** - Protect your data
5. **Explore Advanced Features** - Custom domains, databases, etc.

Continue with:
- [Quick Start Guide](quick-start.md) - Rapid deployment examples
- [Architecture Overview](architecture/index.md) - Understand the system
- [Deployment Patterns](deployment/single-server.md) - Advanced configurations

---

**Next**: [Quick Start Guide](quick-start.md) →
