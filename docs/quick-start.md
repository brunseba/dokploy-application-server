# Quick Start Guide

Get Dokploy up and running in under 10 minutes.

## Prerequisites

- Linux server (Ubuntu/Debian/CentOS)
- 2GB+ RAM
- Root access
- Domain name (optional, for SSL)

## Installation (5 minutes)

### 1. Install Dokploy

```bash
curl -sSL https://dokploy.com/install.sh | sh
```

Wait for installation to complete (~5-10 minutes).

### 2. Access Dashboard

Open your browser:
```
http://YOUR_SERVER_IP:3000
```

Create your admin account with email and password.

## Deploy Your First App (2 minutes)

### From Docker Hub

1. Create a project: "My App"
2. Add application → Docker Image
3. Configure:
   ```
   Image: nginx:alpine
   Port: 80
   ```
4. Click "Deploy"

### From Git Repository

1. Create a project
2. Add application → Git
3. Configure:
   ```
   Repository: https://github.com/user/repo
   Branch: main
   Build: npm install && npm run build
   Start: npm start
   Port: 3000
   ```
4. Click "Deploy"

## Add SSL Certificate (2 minutes)

1. Point DNS A record to your server IP
2. In application settings → Domains
3. Add domain: `app.example.com`
4. Wait for SSL certificate (1-2 minutes)
5. Access: `https://app.example.com`

## Next Steps

- [Getting Started Guide](getting-started.md) - Detailed instructions
- [Traefik OVH DNS Setup](traefik-ovh-dns-setup.md) - Wildcard certificates
- [Deployment Examples](deployment/docker-compose-examples.md) - More examples

---

**Total Time**: ~10 minutes  
**You're ready to deploy!** 🚀
