# ADR-001: Use Docker Swarm for Container Orchestration

**Status**: Accepted  
**Date**: 2024-12-30  
**Deciders**: Architecture Team, Engineering Team  
**Technical Story**: Container orchestration platform selection  

---

## Context

Dokploy requires a container orchestration platform to manage application deployments, handle service scaling, provide high availability, and orchestrate multi-container applications across single or multiple servers. The choice of orchestration platform is a foundational architectural decision that impacts:

- Deployment complexity and learning curve
- Resource requirements (CPU, memory, disk)
- Operational overhead
- Feature availability
- Community support and ecosystem
- Self-hosting feasibility
- Long-term maintainability

### Requirements

**Must Have**:
- Multi-container orchestration
- Service discovery and load balancing
- Rolling updates with zero downtime
- Health checking and auto-restart
- Secret management
- Volume management
- Network isolation
- Resource constraints (CPU, memory)
- Single-server deployment capability
- Multi-server scaling support

**Should Have**:
- Simple installation and configuration
- Low resource overhead
- Native Docker integration
- Built-in overlay networking
- Configuration via declarative files
- CLI and API access

**Nice to Have**:
- GUI/Dashboard
- Extensive plugin ecosystem
- Multi-cloud support
- Advanced scheduling algorithms
- Service mesh integration

### Target User Profile

- Primary: Independent developers and small teams
- Secondary: DevOps engineers in SMBs
- Use case: Self-hosted PaaS with 1-50 applications
- Infrastructure: Single VPS to small clusters (1-10 nodes)
- Expertise level: Beginner to intermediate with containers

---

## Decision

We will use **Docker Swarm** as the container orchestration platform for Dokploy.

---

## Rationale

### Simplicity and Learning Curve

Docker Swarm is significantly simpler than Kubernetes:
- **Setup**: Single command (`docker swarm init`)
- **Learning curve**: Leverages existing Docker knowledge
- **Concepts**: Minimal new abstractions (services, stacks)
- **Configuration**: Standard Docker Compose syntax with minor extensions

This aligns with our "Developer Experience Focus" principle and reduces adoption barriers.

### Resource Efficiency

Docker Swarm has minimal overhead:
- **Control plane**: ~50MB memory per manager node
- **Agent**: Integrated with Docker Engine (no additional daemon)
- **Total overhead**: <100MB vs Kubernetes ~1GB+

This enables deployment on modest hardware (2GB RAM servers), critical for cost-conscious users.

### Built-in Docker Integration

Docker Swarm is:
- Native part of Docker Engine (no separate installation)
- Uses familiar Docker CLI commands
- Compatible with Docker Compose files
- Integrated with Docker networking and volumes

This reduces complexity and maintenance burden.

### Feature Completeness

Docker Swarm provides all required features:
- ✅ Service scaling and replication
- ✅ Rolling updates (parallelism, update order)
- ✅ Health checks (command, interval, retries)
- ✅ Overlay networking
- ✅ Service discovery (DNS-based)
- ✅ Load balancing (built-in)
- ✅ Secret management (encrypted)
- ✅ Config management
- ✅ Placement constraints
- ✅ Resource reservations and limits

### Single-Server Capability

Docker Swarm works perfectly on a single node:
- No quorum requirements for single-node
- Seamless scaling to multi-node when needed
- Same API and behavior across cluster sizes

This is essential for our "Self-Hosting Capable" principle.

### Operational Simplicity

Docker Swarm requires minimal operations:
- No etcd cluster to manage
- No separate control plane components
- No complex networking plugins
- Simple troubleshooting (docker logs, docker inspect)

This aligns with our target user profile (not dedicated DevOps teams).

---

## Alternatives Considered

### Alternative 1: Kubernetes

**Pros**:
- Industry standard with massive ecosystem
- Advanced features (CRDs, operators, service mesh)
- Extensive monitoring and tooling
- Multi-cloud portability
- Large community and knowledge base
- Future-proof technology choice

**Cons**:
- Complex setup and configuration
- Steep learning curve (pods, deployments, services, ingress, etc.)
- High resource requirements (minimum 2GB just for control plane)
- Operational overhead (etcd, API server, scheduler, controller)
- Difficult to run on single modest server
- Not suitable for beginners
- Overengineered for target use case (most users deploy <50 apps)

**Why Not Chosen**:
Kubernetes violates our "Developer Experience Focus" and "Cost-Effectiveness" principles. The complexity-to-benefit ratio is unfavorable for our target users. Most Dokploy users don't need Kubernetes-scale features.

### Alternative 2: Docker Compose (without Swarm)

**Pros**:
- Extremely simple (docker-compose up)
- Familiar to all Docker users
- Minimal learning curve
- Low resource overhead
- Perfect for single-server deployments

**Cons**:
- No built-in service discovery across hosts
- No rolling updates
- No health-based auto-restart at service level
- No built-in secrets management
- No multi-server support
- Manual load balancing required
- No placement constraints

**Why Not Chosen**:
Lacks essential PaaS features like rolling updates, health checks, and multi-server deployment. Not scalable beyond single host.

### Alternative 3: Nomad (HashiCorp)

**Pros**:
- Simpler than Kubernetes
- Multi-cloud and multi-runtime (not just containers)
- Good performance
- Flexible scheduling
- Lower resource usage than Kubernetes

**Cons**:
- Separate project (not part of Docker)
- Additional installation and configuration
- Smaller community than K8s or Swarm
- Requires Consul for service discovery
- Less familiar to Docker users
- More complex than Swarm
- Separate CLI and concepts to learn

**Why Not Chosen**:
Adds complexity without sufficient benefit over Swarm. Not integrated with Docker, requiring users to learn new tools.

### Alternative 4: Amazon ECS / Cloud-specific solutions

**Pros**:
- Managed service (no operational burden)
- Cloud-native integration
- Good performance
- Automatic scaling

**Cons**:
- Vendor lock-in (violates open-source principle)
- Not self-hostable (violates core mission)
- Cloud-only (no on-premise option)
- Costs money
- Different API per cloud provider

**Why Not Chosen**:
Fundamentally incompatible with self-hosting mission. Dokploy must work anywhere.

---

## Consequences

### Positive

1. **Rapid Development**: Simpler architecture accelerates feature development
2. **Lower Barrier to Entry**: Users can start with Docker knowledge
3. **Resource Efficient**: Runs on minimal hardware (enables cost savings)
4. **Operational Simplicity**: Less maintenance burden on users
5. **Familiar Tools**: Docker CLI, Docker Compose compatibility
6. **Quick Onboarding**: Users productive in minutes, not hours/days
7. **Single-Node Friendly**: Perfect for individual developers and startups

### Negative

1. **Ecosystem Size**: Smaller plugin ecosystem than Kubernetes
2. **Community**: Smaller community, fewer third-party tools
3. **Advanced Features**: Missing some K8s features (CRDs, operators, service mesh)
4. **Future Uncertainty**: Docker Swarm in maintenance mode (though stable)
5. **Career Relevance**: K8s experience more valuable in job market
6. **Scalability Ceiling**: Practical limit around 100 nodes (sufficient for us)
7. **Perception**: Some view Swarm as "legacy" vs K8s as "modern"

### Mitigation Strategies

**For Future Uncertainty**:
- Monitor Docker Swarm roadmap quarterly
- Abstract orchestration layer in codebase where possible
- Plan Kubernetes support as Phase 3 (Q2-Q3 2025)
- Provide migration path to K8s when needed

**For Limited Ecosystem**:
- Build necessary tooling ourselves
- Contribute to open-source Swarm tools
- Document workarounds for missing features

**For Scalability Concerns**:
- Current limit (100 nodes, 1000 services) exceeds 99% of users' needs
- Plan K8s support for enterprise users needing massive scale
- Most self-hosted users run 1-5 servers

**For Perception**:
- Focus communication on benefits (simplicity, efficiency)
- Highlight that Swarm is actively maintained and production-ready
- Emphasize perfect fit for target use case
- Offer K8s backend as future option for those who need it

---

## Implementation Details

### Initialization

```bash
# Single-server setup
docker swarm init --advertise-addr <ip>

# Multi-server setup (on workers)
docker swarm join --token <token> <manager-ip>:2377
```

### Service Deployment

```bash
# Deploy application as Swarm service
docker service create \
  --name myapp \
  --replicas 3 \
  --network dokploy-network \
  --publish 8080:80 \
  --constraint 'node.role==worker' \
  myapp:latest
```

### Network Configuration

```bash
# Create overlay network
docker network create --driver overlay --attachable dokploy-network
```

### Updates

```bash
# Rolling update
docker service update --image myapp:v2 --update-parallelism 1 myapp
```

---

## Validation

### Success Criteria

- ✅ Deploy application in <5 minutes
- ✅ Run on 2GB RAM server
- ✅ Zero-downtime updates
- ✅ Support 100+ applications per instance
- ✅ Scale to 50+ servers (covers 99.9% of users)
- ✅ User onboarding <10 minutes

### Monitoring

- Track Docker Swarm development activity
- Monitor user feedback on orchestration
- Measure resource usage in production
- Track feature requests requiring K8s

---

## Related

- **ADR-002**: Next.js architecture (integrates with Docker API)
- **ADR-007**: Traefik configuration (Swarm service discovery)
- **Architecture Vision**: Self-hosting and simplicity principles
- **PRD**: Non-functional requirements (performance, scalability)

---

## References

- [Docker Swarm Mode Overview](https://docs.docker.com/engine/swarm/)
- [Docker Swarm vs Kubernetes](https://circleci.com/blog/docker-swarm-vs-kubernetes/)
- [When to Use Docker Swarm](https://vsupalov.com/docker-swarm/)
- [Docker Swarm Production Deployment](https://docs.docker.com/engine/swarm/admin_guide/)

---

## Decision Log

| Date | Action | Reason |
|------|--------|--------|
| 2024-12-30 | Status: Accepted | Initial architectural decision |
| Future | Review quarterly | Monitor Docker Swarm maintenance status |
| Q2 2025 | Add K8s option | Provide alternative for enterprise users |

---

**Last Updated**: 2024-12-30  
**Next Review**: 2025-03-30  
**Superseded By**: None  
**Supersedes**: None
