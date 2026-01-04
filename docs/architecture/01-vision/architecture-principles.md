# Architecture Principles

**Document Type**: Architecture Vision  
**Status**: Approved  
**Version**: 1.0  
**Last Updated**: 2024-12-30  
**Owner**: Architecture Team  

---

## Purpose

This document defines the core architectural principles that guide all design decisions for Dokploy. These principles ensure consistency, maintainability, and alignment with project goals. When faced with trade-offs, these principles provide a framework for making informed decisions.

---

## Principles Overview

Dokploy is built on eight foundational principles, listed in priority order:

1. **Open Source First**
2. **Self-Hosting Capable**
3. **Security by Design**
4. **Developer Experience Focus**
5. **Cloud-Native Architecture**
6. **API-First Design**
7. **Cost-Effectiveness**
8. **Observability Built-In**

---

## Principle 1: Open Source First

### Statement
All core functionality must be available under an open source license (MIT). Community contributions are encouraged and valued.

### Rationale
- **Transparency**: Users can inspect, audit, and verify the codebase
- **Trust**: No vendor lock-in or hidden behavior
- **Community**: Enable contributions from developers worldwide
- **Innovation**: Accelerate development through collective effort
- **Sustainability**: Open source projects outlive companies

### Implications
- ✅ Core platform: MIT license
- ✅ All source code public on GitHub
- ✅ Contributor-friendly guidelines (CONTRIBUTING.md)
- ✅ Public roadmap and issue tracker
- ❌ No proprietary features in core product
- ❌ No closed-source dependencies when alternatives exist

### Trade-offs
- **Benefit**: Community trust, contributions, transparency
- **Cost**: No competitive moat, copycats possible
- **Mitigation**: Enterprise edition for compliance features (future)

### Validation
- [x] Repository is public
- [x] MIT license applied
- [ ] CONTRIBUTING.md created
- [ ] Public roadmap published

### Examples

**Good**:
```yaml
# All features documented and available
services:
  dokploy:
    image: dokploy/dokploy:latest
    # Full source available at github.com/dokploy/dokploy
```

**Bad**:
```yaml
# Proprietary extension required for basic features
services:
  dokploy-enterprise:
    image: dokploy/dokploy-enterprise:latest
    # Closed source, basic features locked
```

---

## Principle 2: Self-Hosting Capable

### Statement
Dokploy must run on any infrastructure the user controls, from a single VPS to multi-server clusters, without requiring internet connectivity or external services.

### Rationale
- **Data Sovereignty**: Users control their data completely
- **Privacy**: No telemetry or external calls without consent
- **Reliability**: No dependency on third-party SaaS
- **Cost Control**: Users choose infrastructure and budget
- **Compliance**: Meet regulatory requirements (GDPR, HIPAA, etc.)

### Implications
- ✅ Works offline (air-gapped deployments)
- ✅ Single-server minimum (2GB RAM)
- ✅ No mandatory external services
- ✅ Local authentication option
- ✅ Can run on any OS with Docker
- ❌ No required cloud provider services
- ❌ No mandatory telemetry or analytics

### Trade-offs
- **Benefit**: Maximum user control, flexibility, privacy
- **Cost**: More complex deployment, support burden
- **Mitigation**: Excellent documentation, community support

### Validation
- [x] Runs on single server
- [x] No internet required after installation
- [x] Local authentication works
- [x] Tested on major Linux distributions

### Examples

**Good**:
```bash
# Install on any server with Docker
curl -sSL https://dokploy.com/install.sh | sudo bash
# Works completely offline after installation
```

**Bad**:
```bash
# Requires connection to cloud service
dokploy register --api-key YOUR_CLOUD_KEY
# Always phones home, won't work offline
```

---

## Principle 3: Security by Design

### Statement
Security is a first-class requirement, not an afterthought. All features must be designed with security in mind, following defense-in-depth and least-privilege principles.

### Rationale
- **Trust**: Users entrust us with production applications
- **Responsibility**: Security breaches harm users and reputation
- **Compliance**: Many users have regulatory requirements
- **Professionalism**: Security is table stakes for infrastructure

### Implications
- ✅ HTTPS/TLS by default (Let's Encrypt)
- ✅ Authentication required for all operations
- ✅ RBAC with least privilege
- ✅ Secrets encrypted (Docker Swarm secrets)
- ✅ Audit logging for all actions
- ✅ Input validation and sanitization
- ✅ Regular security updates
- ✅ Vulnerability disclosure policy
- ❌ No plain-text passwords stored
- ❌ No secrets in logs or environment variables
- ❌ No insecure defaults

### Trade-offs
- **Benefit**: User trust, compliance, risk reduction
- **Cost**: Additional complexity, slower development
- **Mitigation**: Security tooling, automated testing

### Validation
- [x] TLS certificate management implemented
- [x] Authentication system designed
- [x] Docker secrets integration
- [ ] Security audit completed
- [ ] Vulnerability disclosure policy published

### Examples

**Good**:
```typescript
// Secrets from Docker Swarm secrets
const password = readFileSync('/run/secrets/db_password', 'utf8').trim()

// Authentication required
export async function POST(request: Request) {
  const session = await getServerSession()
  if (!session) {
    return Response.json({ error: 'Unauthorized' }, { status: 401 })
  }
  // ... proceed
}
```

**Bad**:
```typescript
// ❌ Secret in environment variable
const password = process.env.DB_PASSWORD

// ❌ No authentication
export async function POST(request: Request) {
  // Anyone can call this!
  await deployApplication(request.body)
}
```

---

## Principle 4: Developer Experience Focus

### Statement
Prioritize developer productivity and satisfaction. The platform should be intuitive, fast, and enjoyable to use, with minimal learning curve.

### Rationale
- **Adoption**: Great UX drives adoption
- **Retention**: Developers recommend tools they love
- **Efficiency**: Better DX means faster shipping
- **Differentiation**: Simplicity in a complex ecosystem

### Implications
- ✅ Deploy in <5 minutes from first install
- ✅ Intuitive UI with clear information hierarchy
- ✅ Comprehensive, searchable documentation
- ✅ Helpful error messages with solutions
- ✅ Fast feedback loops (immediate deployment status)
- ✅ CLI and GUI options
- ✅ Dark mode support
- ❌ No cryptic error messages
- ❌ No required manual config file editing

### Trade-offs
- **Benefit**: Happy users, positive word-of-mouth, retention
- **Cost**: More investment in UI/UX, documentation
- **Mitigation**: User testing, feedback loops

### Validation
- [ ] <10 minute time to first deployment (user testing)
- [ ] 4.5+ star GitHub rating
- [ ] <3 support questions per new user
- [ ] Documentation completeness audit

### Examples

**Good**:
```
✅ Deploying application "my-app"...
   → Building image from GitHub
   → Pushing to registry
   → Creating Docker service
   → Health check passed
✅ Deployed successfully!
   URL: https://my-app.yourdomain.com
   View logs: dokploy logs my-app
```

**Bad**:
```
Error: deployment failed
Stack trace: ... (500 lines of internal errors)
# No helpful message, no next steps
```

---

## Principle 5: Cloud-Native Architecture

### Statement
Build with cloud-native patterns and practices: containers, orchestration, declarative configuration, immutability, and microservices-ready.

### Rationale
- **Scalability**: Horizontal scaling via containers
- **Portability**: Run anywhere Docker runs
- **Reliability**: Self-healing via orchestration
- **Efficiency**: Resource isolation and optimization
- **Modern**: Align with industry best practices

### Implications
- ✅ Container-first (Docker)
- ✅ Declarative configuration (Docker Compose, Swarm)
- ✅ Immutable deployments
- ✅ Health checks and auto-restart
- ✅ Service discovery built-in
- ✅ Horizontal scaling
- ✅ Rolling updates
- ❌ No VM-based deployments
- ❌ No mutable server state

### Trade-offs
- **Benefit**: Modern architecture, scalability, reliability
- **Cost**: Learning curve for Docker/containers
- **Mitigation**: Documentation, examples, templates

### Validation
- [x] All components containerized
- [x] Health checks implemented
- [x] Rolling update strategy defined
- [ ] Load testing completed

### Examples

**Good**:
```yaml
services:
  app:
    image: myapp:v1.2.3
    deploy:
      replicas: 3
      update_config:
        parallelism: 1
        delay: 10s
      restart_policy:
        condition: on-failure
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost/health"]
      interval: 30s
```

**Bad**:
```bash
# SSH into server and manually update
ssh user@server
cd /var/www/myapp
git pull
pm2 restart myapp
# Manual, error-prone, not scalable
```

---

## Principle 6: API-First Design

### Statement
Design and build APIs before UIs. Every feature must be accessible programmatically, enabling automation and integration.

### Rationale
- **Automation**: Users can script workflows
- **Integration**: Connect with CI/CD, monitoring, etc.
- **Flexibility**: Multiple interfaces (CLI, GUI, SDK)
- **Testing**: APIs easier to test than UIs
- **Future-Proof**: APIs enable unforeseen use cases

### Implications
- ✅ RESTful API for all operations
- ✅ Comprehensive API documentation (OpenAPI/Swagger)
- ✅ API versioning
- ✅ Authentication via API keys/tokens
- ✅ Rate limiting
- ✅ SDK/CLI built on same API as UI
- ❌ No UI-only features
- ❌ No GUI required for core workflows

### Trade-offs
- **Benefit**: Automation, extensibility, power users
- **Cost**: More initial development, documentation
- **Mitigation**: Auto-generated API docs, examples

### Validation
- [ ] OpenAPI spec published
- [x] API authentication designed
- [ ] CLI implements all core features
- [ ] API documentation complete

### Examples

**Good**:
```typescript
// All UI actions call the same API
// POST /api/applications
{
  "name": "my-app",
  "image": "nginx:latest",
  "replicas": 3,
  "envVars": { "PORT": "8080" }
}

// CLI uses same endpoint
$ dokploy deploy my-app --image nginx:latest --replicas 3
```

**Bad**:
```typescript
// UI has direct database access
async function deployApp(data) {
  await db.applications.create(data)
  // No API, can't be automated
}
```

---

## Principle 7: Cost-Effectiveness

### Statement
Minimize resource usage and operational costs for users. Efficient resource utilization enables hosting on modest hardware.

### Rationale
- **Accessibility**: Lower barrier to entry
- **Sustainability**: Environmentally friendly
- **Flexibility**: Users choose infrastructure budget
- **Competitive**: Cost advantage over managed PaaS

### Implications
- ✅ Run on 2GB RAM server
- ✅ Minimal CPU usage when idle
- ✅ Efficient container orchestration (Docker Swarm)
- ✅ Resource limits and reservations
- ✅ Monitoring resource usage
- ✅ Cost calculator/estimator
- ❌ No resource-heavy features without justification
- ❌ No memory leaks

### Trade-offs
- **Benefit**: Accessibility, user savings, sustainability
- **Cost**: May limit feature complexity
- **Mitigation**: Optimize hot paths, benchmark regularly

### Validation
- [x] Runs on 2GB RAM VPS
- [ ] <100MB idle memory usage (core platform)
- [ ] <5% CPU idle usage
- [ ] Resource usage benchmarks documented

### Examples

**Good**:
```yaml
# Efficient resource allocation
services:
  dokploy:
    deploy:
      resources:
        limits:
          memory: 512M
          cpus: '0.5'
        reservations:
          memory: 256M
  # Total overhead: ~512MB
```

**Bad**:
```yaml
# Resource-heavy, requires 8GB+ server
services:
  dokploy:
    deploy:
      resources:
        limits:
          memory: 4G  # Excessive for core platform
          cpus: '2.0'
```

---

## Principle 8: Observability Built-In

### Statement
Provide visibility into system behavior through logs, metrics, and tracing. Users should understand what's happening and diagnose issues easily.

### Rationale
- **Troubleshooting**: Reduce mean time to resolution
- **Confidence**: Users trust what they can observe
- **Optimization**: Measure to improve
- **Proactive**: Detect issues before users report

### Implications
- ✅ Structured logging (JSON)
- ✅ Real-time log streaming
- ✅ Metrics collection (resource usage, request rates)
- ✅ Health checks and status endpoints
- ✅ Audit trail for all actions
- ✅ Integration with monitoring tools (Prometheus, Grafana)
- ✅ Deployment history and rollback
- ❌ No silent failures
- ❌ No missing context in logs

### Trade-offs
- **Benefit**: Easier troubleshooting, user confidence
- **Cost**: Additional storage, complexity
- **Mitigation**: Log retention policies, sampling

### Validation
- [x] Structured logging implemented
- [ ] Real-time log viewer in UI
- [ ] Prometheus metrics exposed
- [ ] Audit log table created

### Examples

**Good**:
```json
// Structured, searchable log
{
  "timestamp": "2024-12-30T12:00:00Z",
  "level": "info",
  "event": "deployment.started",
  "user_id": "user-123",
  "app_id": "app-456",
  "image": "myapp:v1.2.3",
  "replicas": 3
}
```

```typescript
// Health check endpoint
export async function GET(request: Request) {
  const dbHealth = await checkDatabaseConnection()
  const dockerHealth = await checkDockerConnection()
  
  return Response.json({
    status: dbHealth && dockerHealth ? 'healthy' : 'unhealthy',
    checks: { database: dbHealth, docker: dockerHealth },
    timestamp: new Date().toISOString()
  })
}
```

**Bad**:
```bash
# Unstructured, unsearchable log
Deployment started
# Who? What app? When? No context.
```

---

## Principle Conflicts and Resolution

### Conflict 1: Security vs. Developer Experience
**Example**: Requiring MFA adds friction

**Resolution**: 
- Security wins for production environments
- Optional for development mode
- Clear documentation on why security matters

**Precedence**: Principle 3 (Security) > Principle 4 (DX)

### Conflict 2: Cost-Effectiveness vs. Observability
**Example**: Storing detailed logs increases storage costs

**Resolution**:
- Balance: Structured logs with retention policies
- User control: Configurable log levels and retention
- Sampling for high-volume metrics

**Precedence**: Principle 8 (Observability) > Principle 7 (Cost) for troubleshooting

### Conflict 3: Open Source vs. Sustainability
**Example**: Need revenue to fund development

**Resolution**:
- Core: Always open source (MIT)
- Enterprise features: Optional paid edition (compliance, SLA)
- Services: Professional support, consulting

**Precedence**: Principle 1 (Open Source) for core functionality

### Conflict 4: Self-Hosting vs. Ease of Use
**Example**: Managed hosting would be simpler

**Resolution**:
- Maintain self-hosting as primary model
- Partner with hosting providers for "easy deploy" options
- Excellent docs for self-hosting

**Precedence**: Principle 2 (Self-Hosting) > ease of use shortcuts

---

## Principle Application Examples

### Feature: Add Kubernetes Backend

**Evaluation**:
- ✅ Principle 2 (Self-Hosting): Yes, K8s can run on-premise
- ⚠️ Principle 4 (DX Focus): No, K8s increases complexity
- ✅ Principle 5 (Cloud-Native): Yes, K8s is cloud-native
- ⚠️ Principle 7 (Cost): No, K8s requires more resources

**Decision**: Phase 3 feature, after Swarm is proven. Abstract orchestration layer. Optional backend for advanced users.

### Feature: Add AI-Powered Deployment Suggestions

**Evaluation**:
- ❌ Principle 2 (Self-Hosting): Requires external AI service
- ❌ Principle 3 (Security): Sends config data externally
- ❌ Principle 7 (Cost): AI services expensive
- ✅ Principle 4 (DX Focus): Could improve experience

**Decision**: Reject unless fully self-hosted AI model available and optional.

### Feature: Real-Time Collaborative Editing

**Evaluation**:
- ✅ Principle 2 (Self-Hosting): Can be self-hosted (WebSocket)
- ⚠️ Principle 3 (Security): Need conflict resolution, auth
- ✅ Principle 4 (DX Focus): Great for teams
- ⚠️ Principle 7 (Cost): WebSocket overhead

**Decision**: Accept for Phase 2. Benefits outweigh costs for team collaboration.

---

## Principles Checklist

Use this checklist when designing new features:

### Open Source First
- [ ] Feature available in open source edition?
- [ ] No proprietary dependencies?
- [ ] Documented publicly?

### Self-Hosting Capable
- [ ] Works offline/air-gapped?
- [ ] No mandatory external services?
- [ ] Runs on single server?

### Security by Design
- [ ] Threat model created?
- [ ] Secrets encrypted?
- [ ] Authentication required?
- [ ] Input validated?
- [ ] Audit logged?

### Developer Experience
- [ ] Intuitive UI/API?
- [ ] Clear error messages?
- [ ] Documented with examples?
- [ ] Fast feedback?

### Cloud-Native
- [ ] Container-based?
- [ ] Declarative config?
- [ ] Health checks?
- [ ] Horizontally scalable?

### API-First
- [ ] API designed first?
- [ ] API documented?
- [ ] Accessible via CLI?
- [ ] Rate limited?

### Cost-Effectiveness
- [ ] Resource usage measured?
- [ ] Runs on modest hardware?
- [ ] No resource leaks?
- [ ] Benchmarked?

### Observability
- [ ] Logs structured?
- [ ] Metrics exposed?
- [ ] Health checks added?
- [ ] Errors traceable?

---

## Enforcement

### Design Reviews
All significant features must be reviewed against these principles by the architecture team.

### Code Reviews
Pull requests should reference relevant principles when making trade-offs.

### Documentation
Architecture decisions (ADRs) must explain alignment with principles.

### Retrospectives
Quarterly review of principle adherence and effectiveness.

---

## Principle Evolution

These principles are living documents. They should be:
- **Reviewed**: Quarterly by architecture team
- **Updated**: When project direction changes
- **Versioned**: Major changes create new version
- **Communicated**: All changes announced to team

### Change Process
1. Propose principle change (GitHub issue)
2. Architecture team review
3. Community feedback period (2 weeks)
4. Final decision and documentation
5. Update all relevant documents

---

## Related Documents

- **Architecture Vision**: Overall vision and goals
- **Stakeholder Analysis**: Stakeholder needs that inform principles
- **ADRs**: Specific decisions applying these principles
- **PRD**: Product requirements aligned with principles

---

**Document Version**: 1.0  
**Approved By**: Architecture Team  
**Approval Date**: 2024-12-30  
**Next Review**: 2025-03-30
