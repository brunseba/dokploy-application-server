# C4 Container Diagram - Dokploy Internal Architecture

**Document Type**: Architecture View - Container Level  
**C4 Model Level**: Level 2 - Container  
**Version**: 1.0  
**Date**: 2024-12-30  

---

## Overview

This diagram zooms into the Dokploy system boundary and shows the high-level technology choices, how responsibilities are distributed across containers, and how the containers communicate with each other.

## Container Diagram

```mermaid
C4Container
    title Container Diagram for Dokploy Platform

    Person(developer, "Developer", "Deploys and manages applications")
    Person(devops, "DevOps Engineer", "Manages infrastructure")

    System_Boundary(dokploy_boundary, "Dokploy Platform") {
        Container(web_ui, "Web Application", "Next.js, React, TypeScript", "Provides web interface for deployment and management")
        Container(api, "API Server", "Next.js API Routes, Node.js", "Provides REST API and handles business logic")
        Container(postgres, "Database", "PostgreSQL 16", "Stores application configs, users, deployments, metadata")
        Container(redis, "Queue", "Redis 7", "Manages deployment queues and caching")
        Container(traefik, "Reverse Proxy", "Traefik v3.6.1", "Routes traffic, manages SSL, load balancing")
        Container(docker_engine, "Container Runtime", "Docker Engine", "Runs application containers")
    }

    System_Ext(github, "GitHub", "Git repository hosting")
    System_Ext(dockerhub, "Docker Hub", "Container registry")
    System_Ext(letsencrypt, "Let's Encrypt", "SSL certificates")
    System_Ext(s3, "S3 Storage", "Backup storage")

    Rel(developer, web_ui, "Uses", "HTTPS")
    Rel(devops, api, "Automates via", "HTTPS/REST")
    
    Rel(web_ui, api, "Makes API calls", "HTTPS/JSON")
    Rel(api, postgres, "Reads/writes data", "TCP/PostgreSQL Protocol")
    Rel(api, redis, "Enqueues jobs", "TCP/Redis Protocol")
    Rel(api, docker_engine, "Manages containers", "Unix Socket/Docker API")
    Rel(api, github, "Clones repos", "HTTPS/SSH")
    Rel(api, dockerhub, "Pulls/pushes images", "HTTPS")
    Rel(api, s3, "Stores backups", "HTTPS/S3 API")
    
    Rel(traefik, web_ui, "Routes to", "HTTP")
    Rel(traefik, docker_engine, "Discovers services", "Unix Socket/Docker API")
    Rel(traefik, letsencrypt, "Requests certs", "HTTPS/ACME")
    
    Rel(redis, api, "Notifies", "Pub/Sub")
    Rel(docker_engine, traefik, "Registers with", "Docker Labels")

    UpdateLayoutConfig($c4ShapeInRow="3", $c4BoundaryInRow="1")
```

## Container Details

### 1. Web Application (Next.js Frontend)

**Technology**: Next.js 14+, React 18+, TypeScript, Tailwind CSS  
**Port**: 3000  
**Deployment**: Docker Swarm Service  

**Responsibilities**:
- User interface rendering (SSR)
- Client-side state management
- Form validation
- Real-time updates (WebSocket)
- Authentication UI
- Dashboard and metrics visualization

**Key Features**:
- Server-side rendering for performance
- Responsive design
- Dark mode support
- Real-time log streaming
- Interactive deployment interface
- Role-based UI rendering

**Dependencies**:
- API Server (for all data operations)
- WebSocket connection for real-time updates

---

### 2. API Server (Backend)

**Technology**: Next.js API Routes, Node.js 18+  
**Port**: 3000 (same process as Web App)  
**Deployment**: Docker Swarm Service  

**Responsibilities**:
- Business logic execution
- Authentication and authorization
- Deployment orchestration
- Docker container management
- Git operations
- Database operations
- Queue management
- Webhook handling

**Key Features**:
- RESTful API endpoints
- JWT-based authentication
- Role-based access control (RBAC)
- Deployment queue management
- Background job processing
- Git repository cloning
- Docker image building
- Container lifecycle management

**API Endpoints**:
- `/api/auth/*` - Authentication
- `/api/projects/*` - Project management
- `/api/applications/*` - Application deployment
- `/api/databases/*` - Database management
- `/api/servers/*` - Remote server management
- `/api/deployments/*` - Deployment operations
- `/api/domains/*` - Domain configuration
- `/api/monitoring/*` - Metrics and logs

**Dependencies**:
- PostgreSQL (data persistence)
- Redis (queue and cache)
- Docker Engine (container management)
- Git providers (source code)
- Container registries (images)

---

### 3. PostgreSQL Database

**Technology**: PostgreSQL 16  
**Port**: 5432  
**Deployment**: Docker Swarm Service  

**Responsibilities**:
- Persistent data storage
- Transactional integrity
- Data relationships
- Query optimization
- Backup and recovery

**Schema Overview**:
- **users**: User accounts and authentication
- **organizations**: Multi-tenant organizations
- **projects**: Project containers
- **applications**: Application configurations
- **databases**: Database instances
- **deployments**: Deployment history
- **servers**: Remote server configurations
- **domains**: Domain and SSL configurations
- **environment_variables**: Encrypted env vars
- **logs**: Audit logs

**Data Volume**: `dokploy-postgres`  
**Backup Strategy**: Automated dumps to S3  
**Security**: Encrypted at rest, SSL connections  

---

### 4. Redis Queue

**Technology**: Redis 7  
**Port**: 6379  
**Deployment**: Docker Swarm Service  

**Responsibilities**:
- Deployment queue management
- Job scheduling
- Caching layer
- Pub/Sub messaging
- Session storage

**Usage Patterns**:
- **Queue**: Deployment jobs (prevents concurrent deploys)
- **Cache**: Frequently accessed data (user sessions, configs)
- **Pub/Sub**: Real-time notifications to UI
- **Lock**: Distributed locking for critical operations

**Data Structure**:
```
deployments:queue          # Deployment job queue
deployments:active:{id}    # Active deployment tracking
cache:user:{id}           # User session cache
cache:metrics:{app_id}    # Metrics cache
pubsub:logs:{app_id}      # Log streaming channel
locks:deploy:{app_id}     # Deployment locks
```

**Data Volume**: `dokploy-redis`  
**Persistence**: RDB snapshots + AOF  

---

### 5. Traefik Reverse Proxy

**Technology**: Traefik v3.6.1  
**Ports**: 80 (HTTP), 443 (HTTPS), 443/UDP (HTTP/3)  
**Deployment**: Docker Container (not Swarm service)  

**Responsibilities**:
- HTTP/HTTPS traffic routing
- SSL/TLS termination
- Load balancing
- Service discovery
- Certificate management
- Rate limiting
- Request middlewares

**Configuration**:
- **Static Config**: `/etc/dokploy/traefik/traefik.yml`
- **Dynamic Config**: `/etc/dokploy/traefik/dynamic/`
- **Certificates**: `/etc/dokploy/traefik/acme.json`

**Features**:
- Automatic service discovery via Docker labels
- Let's Encrypt integration (HTTP-01, DNS-01)
- HTTP to HTTPS redirect
- WebSocket support
- HTTP/3 (QUIC) support
- Security headers
- Rate limiting
- Compression

**Routing Logic**:
```
Request → Traefik → Check Host header → Route to container
                  → Check Path → Apply middlewares
                  → SSL termination → Forward to backend
```

---

### 6. Docker Engine

**Technology**: Docker 28.5.0+, Docker Swarm  
**Socket**: `/var/run/docker.sock`  
**Deployment**: Host system service  

**Responsibilities**:
- Container lifecycle management
- Image building
- Network management
- Volume management
- Swarm orchestration
- Service scaling

**Managed Resources**:
- Application containers (deployed apps)
- Database containers (PostgreSQL, MySQL, MongoDB, Redis)
- Build containers (temporary)
- Networks (overlay, bridge)
- Volumes (persistent storage)
- Secrets (sensitive data)

**Swarm Features**:
- Service replication
- Rolling updates
- Health checks
- Resource constraints
- Secret management
- Config management

---

## Communication Patterns

### Synchronous Communication

| Source | Destination | Protocol | Purpose |
|--------|-------------|----------|---------|
| Web UI | API Server | HTTPS/REST | All user operations |
| API Server | PostgreSQL | TCP/SQL | Data persistence |
| API Server | Redis | TCP/Redis | Queue operations |
| API Server | Docker | Unix Socket | Container management |
| Traefik | Docker | Unix Socket | Service discovery |
| Traefik | Let's Encrypt | HTTPS/ACME | Certificate issuance |

### Asynchronous Communication

| Source | Destination | Mechanism | Purpose |
|--------|-------------|-----------|---------|
| API Server | Redis | Queue | Deployment jobs |
| Redis | API Server | Pub/Sub | Job notifications |
| Docker | Traefik | Events | Service updates |
| External | API Server | Webhooks | Git push events |

### Real-Time Communication

| Source | Destination | Protocol | Purpose |
|--------|-------------|----------|---------|
| API Server | Web UI | WebSocket | Log streaming |
| API Server | Web UI | WebSocket | Deployment status |
| API Server | Web UI | Server-Sent Events | Metrics updates |

---

## Data Flow

### Deployment Flow

```
1. Developer pushes code to GitHub
2. GitHub sends webhook to API Server (via Traefik)
3. API Server enqueues deployment job in Redis
4. API Server processes job from queue
5. API Server clones repository
6. API Server builds Docker image
7. Docker Engine creates container
8. Container registers with Traefik (via labels)
9. Traefik routes traffic to container
10. API Server stores deployment record in PostgreSQL
```

### Certificate Provisioning Flow

```
1. User configures domain in Web UI
2. API Server creates Traefik configuration
3. Traefik detects new configuration
4. Traefik requests certificate from Let's Encrypt
5. Let's Encrypt validates domain (HTTP-01/DNS-01)
6. Traefik stores certificate in acme.json
7. Traefik automatically renews before expiry
```

### Backup Flow

```
1. Cron job triggers backup in API Server
2. API Server connects to database container
3. API Server creates database dump
4. API Server uploads dump to S3
5. API Server stores backup metadata in PostgreSQL
6. API Server sends notification (optional)
```

---

## Security Architecture

### Network Isolation

```
Internet → Port 80/443 → Traefik → dokploy-network → Containers
                                   ↓
                              PostgreSQL (not exposed)
                              Redis (not exposed)
```

### Authentication Flow

```
User → Web UI → API Server → JWT Token
                           → Session in Redis
                           → 2FA validation (if enabled)
                           → User record in PostgreSQL
```

### Secrets Management

- **Environment Variables**: Encrypted in PostgreSQL with AES-256
- **Docker Secrets**: Managed by Docker Swarm
- **SSH Keys**: Stored encrypted in PostgreSQL
- **API Keys**: Hashed in PostgreSQL
- **Certificates**: Stored in Traefik acme.json (600 permissions)

---

## Scalability Considerations

### Horizontal Scaling

- **Web UI/API**: Can run multiple replicas (load balanced by Traefik)
- **Worker Processes**: Can scale deployment workers independently
- **Database**: Single primary (read replicas possible)
- **Redis**: Single instance (cluster mode future enhancement)

### Vertical Scaling

- **PostgreSQL**: Scale storage, increase memory/CPU
- **Redis**: Increase memory for larger queues/cache
- **Docker Engine**: Scale host resources

### Resource Limits

Each container can specify:
- CPU limits and reservations (NanoCPUs)
- Memory limits and reservations (bytes)
- Disk I/O limits
- Network bandwidth (via Docker)

---

## Monitoring and Observability

### Metrics Collection

```
Docker Engine → Container stats → API Server → PostgreSQL
                                             → Redis (cache)
                                             → Web UI (real-time)
```

### Log Aggregation

```
Container stdout/stderr → Docker logs → API Server → Web UI streaming
                                                   → PostgreSQL (audit logs)
```

### Health Checks

- **Web UI/API**: HTTP GET `/health`
- **PostgreSQL**: `pg_isready`
- **Redis**: `PING` command
- **Traefik**: HTTP GET `/ping`
- **Application Containers**: Custom health checks

---

## Deployment Configuration

### Docker Compose Equivalent

```yaml
version: '3.8'

services:
  dokploy:
    image: dokploy/dokploy:latest
    ports:
      - "3000:3000"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - /etc/dokploy:/etc/dokploy
    environment:
      - DATABASE_URL=postgresql://dokploy:***@postgres:5432/dokploy
      - REDIS_URL=redis://redis:6379
    depends_on:
      - postgres
      - redis

  postgres:
    image: postgres:16
    volumes:
      - dokploy-postgres:/var/lib/postgresql/data
    environment:
      - POSTGRES_DB=dokploy
      - POSTGRES_USER=dokploy
      - POSTGRES_PASSWORD=***

  redis:
    image: redis:7
    volumes:
      - dokploy-redis:/data

  traefik:
    image: traefik:v3.6.1
    ports:
      - "80:80"
      - "443:443"
      - "443:443/udp"
    volumes:
      - /etc/dokploy/traefik:/etc/traefik
      - /var/run/docker.sock:/var/run/docker.sock:ro

networks:
  dokploy-network:
    driver: overlay

volumes:
  dokploy-postgres:
  dokploy-redis:
```

---

## Technology Decisions

### Why Next.js?
- Unified frontend/backend reduces complexity
- Server-side rendering improves performance
- Built-in API routes eliminate separate backend
- TypeScript support throughout
- Active ecosystem and community

### Why PostgreSQL?
- ACID compliance for critical data
- Rich feature set (JSONB, full-text search)
- Excellent Node.js support
- Mature backup/recovery tools
- Wide industry adoption

### Why Redis?
- High-performance queue management
- Low latency caching
- Pub/Sub for real-time features
- Simple deployment
- Atomic operations

### Why Traefik?
- Native Docker integration
- Automatic service discovery
- Let's Encrypt integration
- Modern features (HTTP/3, WebSocket)
- Dynamic configuration

---

## Related Diagrams

- **Context Diagram**: System boundary and external integrations
- **Component Diagram**: Internal structure of Next.js application
- **Deployment Diagram**: Physical infrastructure layout
- **Sequence Diagrams**: Detailed interaction flows

---

**Document Owner**: Architecture Team  
**Related Standards**: C4 Model Level 2, Docker Best Practices  
**Next Level**: Component Diagram (internal structure)  
**Review Cycle**: Quarterly
