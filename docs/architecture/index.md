# Architecture Overview

This section contains comprehensive TOGAF 9.2-compliant architecture documentation for Dokploy, a self-hosted Platform-as-a-Service (PaaS) solution.

## Documentation Structure

The architecture documentation follows The Open Group Architecture Framework (TOGAF) 9.2 methodology, covering all eight core phases of the Architecture Development Method (ADM).

## TOGAF Phases

### Phase A: Architecture Vision
Establishes the architectural vision, identifies stakeholders, and defines guiding principles.

- **[Architecture Vision](01-vision/architecture-vision.md)** - High-level vision, scope, and objectives
- **[Stakeholder Analysis](01-vision/stakeholder-analysis.md)** - Stakeholder identification, concerns, and engagement strategy
- **[Architecture Principles](01-vision/architecture-principles.md)** - 15 core principles guiding architecture decisions

**Key Highlights:**
- Vision: Simplify self-hosted PaaS deployment
- 6 Primary stakeholder groups (DevOps Engineers, Platform Engineers, Developers, System Administrators, Security Teams, End Users)
- Core principles: Simplicity, Security by Design, Open Standards

---

### Phase B: Business Architecture
Describes the business strategy, governance, processes, and capabilities.

- **[Business Capability Model](02-business/business-capability-model.md)** - 7 core business capabilities
- **[Value Stream Mapping](02-business/value-stream-mapping.md)** - 5 value streams with lead time analysis

**Key Highlights:**
- Capabilities: Application Deployment, Infrastructure Management, Security & Compliance
- Primary Value Stream: Application Deployment (target lead time: 5 minutes)
- Stakeholder value mapping for all personas

---

### Phase C: Data Architecture
Defines the data architecture including entities, relationships, and data flows.

- **[Data Model](03-data/data-model.md)** - Complete data model with 17 entities and ERD

**Key Highlights:**
- 17 Core entities (User, Team, Project, Application, Database, Deployment, etc.)
- Entity Relationship Diagram (ERD) with Mermaid
- CRUD operations matrix
- Data governance policies

---

### Phase D: Application Architecture
Describes the application components, APIs, and data flows.

- **[Data Flow Diagram](04-application/data-flow-diagram.md)** - 6 comprehensive flow patterns
- **[Application Component Diagram](04-application/application-component-diagram.md)** - 10 core components with code examples
- **[API Specification](04-application/api-specification.md)** - Complete REST API documentation

**Key Highlights:**
- Flow Patterns: User Request-Response, Deployment, Authentication, Monitoring, Backup, TLS Certificate
- Components: Web Layer, API Routes, Auth Module, Deployment Engine, Monitoring Service
- API: REST with JWT + OIDC, WebSocket for real-time updates, SDK examples

---

### Phase E: Technology Architecture
Defines the technology stack, infrastructure, and deployment architecture.

- **[Technology Stack](05-technology/technology-stack.md)** - Comprehensive technology inventory with versions and licenses

**Key Highlights:**
- Orchestration: Docker Swarm
- Frontend: Next.js 14, Material UI
- Backend: Node.js, Prisma ORM
- Database: PostgreSQL 16, Redis 7
- Reverse Proxy: Traefik 3.6.1
- Cloud provider compatibility matrix

---

### Phase F: Opportunities & Solutions
This phase is represented through architectural views and requirements traceability.

#### Architectural Views
Provides multiple perspectives on the system architecture.

- **[Context Diagram](06-views/context-diagram.md)** - System context and external actors
- **[Container Diagram](06-views/container-diagram.md)** - High-level technology choices
- **[Security View](06-views/security-view.md)** - Security architecture with 5 zones
- **[Deployment Diagram](06-views/deployment-diagram.md)** - Three deployment patterns

**Key Highlights:**
- 5 Security Zones: DMZ, Application, Data, Management, External
- Deployment Patterns: Single-server, Multi-server, High Availability
- Mermaid diagrams for all views

#### Requirements
- **[Requirements Traceability Matrix](07-requirements/requirements-traceability-matrix.md)** - Complete mapping of requirements to architecture

**Key Highlights:**
- 70+ Functional requirements
- 35+ Non-functional requirements
- Compliance matrix (OWASP, CIS, GDPR, SOC 2)
- Test coverage matrix

---

### Phase G: Migration Planning
Defines the implementation roadmap and migration strategy.

- **[Implementation Roadmap](09-implementation/implementation-roadmap.md)** - 4-phase, 52-week implementation plan

**Key Highlights:**
- 4 Phases: Foundation, Core, Advanced, Enterprise
- 26 Sprints (2-week iterations)
- Resource planning with budget estimates ($678k total)
- Risk management and mitigation strategies
- Go-to-market strategy

---

### Phase H: Architecture Governance
Establishes governance processes, standards, and metrics.

- **[Architecture Governance Model](10-governance/architecture-governance-model.md)** - Complete governance framework

**Key Highlights:**
- 3-Body governance structure (Executive Steering Committee, Architecture Review Board, Architecture Team)
- 4-Level decision-making framework
- ADR (Architecture Decision Record) process and lifecycle
- Architecture review processes (pre/post-implementation)
- Compliance management and monitoring
- Architecture standards (code, API, security, database)
- Exception handling process
- Continuous improvement model

---

### Architecture Decisions (ADRs)
Documents key architectural decisions with context, rationale, and consequences.

- **[ADR-001: Docker Swarm Orchestration](08-decisions/ADR-001-docker-swarm-orchestration.md)**
  - Status: Accepted
  - Decision: Use Docker Swarm for container orchestration
  - Rationale: Simplicity, built-in clustering, lower resource overhead vs Kubernetes

- **[ADR-002: Next.js Framework](08-decisions/ADR-002-nextjs-framework.md)**
  - Status: Accepted
  - Decision: Use Next.js 14 with App Router as full-stack framework
  - Rationale: Unified codebase, TypeScript support, modern developer experience

- **[ADR-003: PostgreSQL Database](08-decisions/ADR-003-postgresql-database.md)**
  - Status: Accepted
  - Decision: Use PostgreSQL 16 as primary database
  - Rationale: JSONB support, Row Level Security, battle-tested reliability

---

## Architecture Highlights

### System Overview
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

### Key Metrics

| Metric | Value |
|--------|-------|
| **Total Documents** | 21 |
| **Total Lines** | ~16,138 |
| **Estimated Words** | ~194,000 |
| **Mermaid Diagrams** | 45+ |
| **Code Examples** | 150+ |
| **TOGAF Phases Covered** | 8/8 (100%) |

### Technology Summary

| Layer | Technology | Version |
|-------|------------|---------|
| **Orchestration** | Docker Swarm | 28.5.0 |
| **Frontend** | Next.js | 14.x |
| **UI Framework** | Material UI | 5.x |
| **Backend** | Node.js | 20.x LTS |
| **ORM** | Prisma | 5.x |
| **Database** | PostgreSQL | 16.x |
| **Cache** | Redis | 7.x |
| **Job Queue** | BullMQ | 5.x |
| **Reverse Proxy** | Traefik | 3.6.1 |
| **Authentication** | JWT + OIDC | - |

### Security Architecture

**5 Security Zones:**
1. **DMZ Zone** - Traefik reverse proxy with WAF
2. **Application Zone** - Dokploy application containers
3. **Data Zone** - PostgreSQL and Redis with encryption
4. **Management Zone** - Monitoring and admin tools
5. **External Zone** - GitHub, Docker Hub, OVH DNS

**Security Controls:**
- AES-256-GCM encryption at rest
- TLS 1.3 for all communications
- RBAC with team-based permissions
- Rate limiting and DDoS protection
- Container isolation and resource limits
- Security scanning and vulnerability management

### Deployment Options

**1. Single Server** (2GB+ RAM)
- All components on one node
- Suitable for development and small teams
- Quick setup and easy maintenance

**2. Multi-Server** (3+ nodes)
- Distributed deployment for scalability
- Separate application and database nodes
- Horizontal scaling capability

**3. High Availability** (3+ nodes, HA setup)
- 3-node cluster with automatic failover
- Database replication and backup
- 99.9% uptime SLA
- Geographic distribution support

---

## Using This Documentation

### For Architects
Start with the [Architecture Vision](01-vision/architecture-vision.md) to understand the overall vision and principles, then explore specific phases relevant to your concerns.

### For Developers
Focus on:
- [Data Model](03-data/data-model.md) - Understand the data structure
- [Application Component Diagram](04-application/application-component-diagram.md) - Component interactions
- [API Specification](04-application/api-specification.md) - API endpoints and examples

### For DevOps Engineers
Focus on:
- [Technology Stack](05-technology/technology-stack.md) - Technology choices
- [Deployment Diagram](06-views/deployment-diagram.md) - Deployment patterns
- [Implementation Roadmap](09-implementation/implementation-roadmap.md) - Implementation timeline

### For Security Teams
Focus on:
- [Security View](06-views/security-view.md) - Security architecture
- [Requirements Traceability Matrix](07-requirements/requirements-traceability-matrix.md) - Compliance mapping
- [Architecture Governance Model](10-governance/architecture-governance-model.md) - Governance and standards

---

## Document Status

| Phase | Documents | Status | Completion |
|-------|-----------|--------|------------|
| **Phase A: Vision** | 3 | ✅ Complete | 100% |
| **Phase B: Business** | 2 | ✅ Complete | 100% |
| **Phase C: Data** | 1 | ✅ Complete | 100% |
| **Phase D: Application** | 3 | ✅ Complete | 100% |
| **Phase E: Technology** | 1 | ✅ Complete | 100% |
| **Architectural Views** | 4 | ✅ Complete | 100% |
| **Phase F: Requirements** | 1 | ✅ Complete | 100% |
| **Phase G: Migration** | 1 | ✅ Complete | 100% |
| **Phase H: Governance** | 1 | ✅ Complete | 100% |
| **ADRs** | 3 | ✅ Complete | 100% |
| **TOTAL** | **21** | ✅ **Complete** | **100%** |

---

## Maintenance and Updates

This architecture documentation is maintained as a living document. Updates are tracked through:
- Git version control
- Architecture Decision Records (ADRs) for significant changes
- Regular architecture reviews (quarterly)
- Stakeholder feedback incorporation

**Last Major Update**: 2024-12-31  
**Next Scheduled Review**: 2025-03-31  
**Status**: Production Ready

---

## Related Documentation

- [Traefik OVH DNS Setup Guide](../traefik-ovh-dns-setup.md) - Configure SSL with OVH DNS
- [Deployment Guides](../deployment/) - Deployment patterns and examples
- [Operations Guides](../operations/) - Monitoring, maintenance, and security
- [API Reference](../reference/api.md) - Complete API documentation

---

**Architecture Framework**: TOGAF 9.2  
**Compliance Level**: Level 3 (Target: Level 4)  
**Version**: 1.0.0
