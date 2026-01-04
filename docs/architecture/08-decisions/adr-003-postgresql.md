# ADR-003: Use PostgreSQL as Primary Database

**Status**: Accepted  
**Date**: 2024-12-30  
**Deciders**: Architecture Team, Engineering Team  
**Technical Story**: Relational database selection for application metadata  

---

## Context

Dokploy requires a persistent data store for:

1. **Application Metadata**: Service configurations, deployment history, environment variables
2. **User Management**: Accounts, authentication tokens, permissions (RBAC)
3. **Project Organization**: Projects, teams, resource grouping
4. **Audit Logs**: User actions, deployment events, system changes
5. **Monitoring Data**: Historical metrics, alerts, health check results
6. **Resource Quotas**: Usage tracking, limits, billing information
7. **Git Integration**: Repository links, branch configurations, webhooks
8. **Backup Configuration**: Schedule, retention policies, destinations

The database must support:
- ACID transactions (data consistency)
- Complex queries (joins, aggregations, filtering)
- Full-text search (logs, application names)
- JSON data (flexible schemas for metadata)
- Concurrent access (multiple users)
- Data integrity (foreign keys, constraints)
- Backup and recovery
- Reasonable performance (<100ms typical queries)

### Requirements

**Must Have**:
- ACID compliance
- SQL query support
- Foreign key constraints
- Indexing capability
- JSON/JSONB support
- Full-text search
- Transaction support
- Backup/restore tools
- Replication capability
- Open source
- Self-hostable
- Mature and stable

**Should Have**:
- PostgreSQL compatibility (for ecosystem)
- Good TypeScript/Node.js drivers
- Migration tool support
- Query explain/analysis
- Connection pooling
- Row-level security
- Trigger support
- View support

**Nice to Have**:
- Time-series data support
- Geographic data types
- Array data types
- Range types
- Advanced indexing (GIN, GiST)
- Partitioning
- Parallel query execution

### Data Volume Estimates

- Users: 1-10,000 per instance
- Applications: 10-1,000 per instance
- Deployments: 1,000-100,000 per instance (historical)
- Audit logs: 10,000-1,000,000 rows
- Total database size: 100MB-10GB typical

---

## Decision

We will use **PostgreSQL 16+** as the primary relational database for Dokploy.

---

## Rationale

### Industry Standard

PostgreSQL is the most popular open-source RDBMS:
- DB-Engines ranking: #4 overall, #1 open-source RDBMS
- Used by: Apple, Netflix, Spotify, Reddit, Instagram
- 35+ years of development (since 1986)
- Trusted for mission-critical applications

This reduces risk and ensures long-term viability.

### Feature Completeness

PostgreSQL provides all required features:
- ✅ Full ACID compliance
- ✅ Advanced SQL support (CTEs, window functions, etc.)
- ✅ JSONB (binary JSON, indexed, queryable)
- ✅ Full-text search (tsvector, tsquery)
- ✅ Foreign keys and constraints
- ✅ Advanced indexing (B-tree, Hash, GiST, GIN, BRIN)
- ✅ Triggers and stored procedures
- ✅ Views and materialized views
- ✅ Row-level security (for RBAC)
- ✅ Replication (streaming, logical)
- ✅ Partitioning (range, list, hash)

No feature gaps for our use case.

### JSON Support (JSONB)

PostgreSQL's JSONB is ideal for flexible metadata:
- Binary format (faster than text JSON)
- Indexable with GIN indexes
- Query with JSON operators (`->`, `->>`, `@>`, etc.)
- Validate with JSON schema (via extensions)

Example use cases:
- Application environment variables (variable schema)
- Docker labels and metadata
- Webhook payloads
- Deployment configurations

This eliminates need for separate document database.

### Full-Text Search

PostgreSQL includes robust FTS:
- Built-in `tsvector` and `tsquery` types
- Multiple language support
- Ranking and relevance scoring
- Phrase search, proximity search

This eliminates need for separate search engine (Elasticsearch) for most use cases.

### Excellent TypeScript/Node.js Ecosystem

PostgreSQL has mature Node.js support:
- **node-postgres (pg)**: Most popular, 18M+ weekly downloads
- **Prisma**: Modern ORM with excellent TypeScript support
- **Drizzle ORM**: Lightweight, type-safe
- **TypeORM**: Feature-rich ORM
- **Knex.js**: Query builder

This enables rapid development with type safety.

### Operational Maturity

PostgreSQL offers production-ready operations:
- `pg_dump` / `pg_restore` for backups
- Point-in-time recovery (PITR)
- Streaming replication (simple setup)
- Logical replication (selective)
- Hot standby (read replicas)
- Vacuum for maintenance
- Extensive monitoring (pg_stat_*)

Well-documented operational procedures reduce risk.

### Performance

PostgreSQL performs well for our scale:
- Single-server handles 10,000+ TPS
- Connection pooling (PgBouncer)
- Query planner with statistics
- Parallel query execution (v9.6+)
- JIT compilation (v11+)
- Partitioning for large tables

Our workload (mostly reads, <1000 writes/minute) well within capabilities.

### Docker Ecosystem Integration

PostgreSQL is first-class in Docker:
- Official Docker images
- Well-documented configuration
- Health checks built-in
- Volume management patterns
- Swarm deployment examples

Aligns with our Docker-first architecture.

---

## Alternatives Considered

### Alternative 1: MySQL/MariaDB

**Pros**:
- Also very popular
- Good performance
- Mature replication
- Large community
- Good tooling

**Cons**:
- Weaker JSON support (no JSONB equivalent until v8.0)
- Less advanced SQL features
- Full-text search less powerful
- More licensing complexity (Oracle ownership)
- Different behaviors across storage engines

**Why Not Chosen**:
PostgreSQL's superior JSON and full-text search capabilities are critical for our flexible metadata requirements. MariaDB improves on MySQL but still lags PostgreSQL in these areas.

### Alternative 2: SQLite

**Pros**:
- Extremely simple (file-based)
- Zero configuration
- No separate process
- Very fast for small workloads
- Perfect for development

**Cons**:
- No concurrent writes (WAL mode helps but limited)
- No network access (must be on same host)
- Limited replication options
- No user management
- Not suitable for multi-server
- Limited full-text search

**Why Not Chosen**:
Insufficient for production PaaS. Dokploy requires concurrent access from multiple users, network-based access for monitoring, and future multi-server support.

Could be used for development/testing, but maintaining two database systems adds complexity.

### Alternative 3: MongoDB

**Pros**:
- Flexible schema (document-based)
- Horizontal scaling
- Good performance
- Large community
- Rich query language

**Cons**:
- No ACID transactions across documents (until v4.0)
- No foreign keys or joins (denormalization required)
- Eventual consistency issues
- More complex to operate
- Larger resource usage
- Not relational (awkward for our data model)

**Why Not Chosen**:
Our data is highly relational (users → projects → applications → deployments). Forcing this into a document model would be awkward and lose referential integrity benefits. PostgreSQL's JSONB provides flexibility where needed without sacrificing relational model.

### Alternative 4: CockroachDB

**Pros**:
- PostgreSQL-compatible
- Distributed by design
- Horizontal scalability
- Strong consistency
- Cloud-native
- Excellent for multi-region

**Cons**:
- Overkill for single-server deployments
- Higher resource usage (Raft consensus)
- More operational complexity
- Less mature than PostgreSQL
- Smaller community
- Some PostgreSQL features missing

**Why Not Chosen**:
Overengineered for our target use case (mostly single-server deployments). CockroachDB's distributed architecture is powerful but unnecessary complexity for 99% of our users.

Consider for future "Dokploy Enterprise" offering.

### Alternative 5: TimescaleDB (PostgreSQL extension)

**Pros**:
- PostgreSQL extension (not separate DB)
- Excellent for time-series data
- Automatic partitioning
- Continuous aggregates
- Retention policies
- Compression

**Cons**:
- Additional complexity (extension installation)
- Not needed for current requirements
- Our time-series data is minimal (metrics)

**Why Not Chosen**:
While TimescaleDB is excellent, plain PostgreSQL is sufficient for our time-series needs (metrics, logs). We can add TimescaleDB later if needed without migration.

### Alternative 6: Supabase (Managed PostgreSQL)

**Pros**:
- Managed PostgreSQL
- Built-in authentication
- Real-time subscriptions
- Auto-generated APIs
- Storage included

**Cons**:
- Cloud-only (violates self-hosting principle)
- Vendor lock-in
- Costs money
- Requires internet access
- Not suitable for air-gapped deployments

**Why Not Chosen**:
Fundamentally incompatible with self-hosting mission. Dokploy must work anywhere, including on-premise and air-gapped environments.

---

## Consequences

### Positive

1. **Feature-Rich**: All needed features without additional tools
2. **Type Safety**: Excellent TypeScript ORM support (Prisma, Drizzle)
3. **No Feature Creep**: Don't need separate search/document DB
4. **Operational Simplicity**: Well-known backup/monitoring procedures
5. **Community Support**: Huge community, extensive documentation
6. **Future-Proof**: Actively developed, 35+ year track record
7. **Cost-Effective**: Free and open source
8. **Talent Pool**: Most developers know PostgreSQL

### Negative

1. **Single Point of Failure**: Without replication, DB is SPOF
2. **Scaling Ceiling**: Vertical scaling limits (~100K concurrent connections)
3. **Backup Downtime**: pg_dump locks tables briefly
4. **Resource Usage**: ~50-100MB RAM minimum
5. **Complexity**: More complex than SQLite
6. **Maintenance**: Requires VACUUM, ANALYZE, reindexing

### Mitigation Strategies

**For Single Point of Failure**:
- Provide streaming replication setup guide
- Automated backups (hourly to daily)
- Document recovery procedures
- Plan high-availability configuration (Phase 3)

**For Scaling Ceiling**:
- Use connection pooling (PgBouncer)
- Current ceiling (millions of users) far exceeds 99.9% use cases
- Plan sharding for massive deployments (Phase 4, 2026+)

**For Backup Impact**:
- Use `pg_dump -Fc` (custom format, faster)
- Schedule during low-traffic periods
- Use replication for zero-downtime backups
- Document point-in-time recovery

**For Resource Usage**:
- Tune PostgreSQL configuration for VPS sizes
- Provide config templates (2GB, 4GB, 8GB RAM)
- Monitor and alert on resource usage

**For Maintenance**:
- Enable `autovacuum` (default in modern PostgreSQL)
- Automated maintenance scripts
- Monitoring for bloat
- Documentation for common operations

---

## Implementation Details

### Docker Configuration

```yaml path=/docker-compose.yml start=null
services:
  postgres:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: dokploy
      POSTGRES_USER: dokploy
      POSTGRES_PASSWORD_FILE: /run/secrets/postgres_password
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./init.sql:/docker-entrypoint-initdb.d/init.sql
    secrets:
      - postgres_password
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U dokploy"]
      interval: 10s
      timeout: 5s
      retries: 5
    deploy:
      resources:
        limits:
          memory: 1G
        reservations:
          memory: 512M

volumes:
  postgres_data:

secrets:
  postgres_password:
    external: true
```

### Schema Example

```sql path=/init.sql start=null
-- Users table
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  username VARCHAR(255) NOT NULL UNIQUE,
  email VARCHAR(255) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  role VARCHAR(50) NOT NULL DEFAULT 'user',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);

-- Projects table
CREATE TABLE projects (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  description TEXT,
  owner_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_projects_owner ON projects(owner_id);
CREATE INDEX idx_projects_metadata ON projects USING GIN (metadata);

-- Applications table
CREATE TABLE applications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  type VARCHAR(50) NOT NULL, -- docker, git, compose
  source_type VARCHAR(50), -- github, gitlab, docker
  source_config JSONB DEFAULT '{}',
  env_vars JSONB DEFAULT '{}',
  docker_config JSONB DEFAULT '{}',
  status VARCHAR(50) NOT NULL DEFAULT 'stopped',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  UNIQUE(project_id, name)
);

CREATE INDEX idx_apps_project ON applications(project_id);
CREATE INDEX idx_apps_status ON applications(status);
CREATE INDEX idx_apps_env ON applications USING GIN (env_vars);

-- Deployments table (time-series pattern)
CREATE TABLE deployments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  application_id UUID NOT NULL REFERENCES applications(id) ON DELETE CASCADE,
  status VARCHAR(50) NOT NULL, -- pending, running, success, failed
  commit_sha VARCHAR(40),
  triggered_by UUID REFERENCES users(id),
  logs TEXT,
  metadata JSONB DEFAULT '{}',
  started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  completed_at TIMESTAMPTZ
);

CREATE INDEX idx_deployments_app ON deployments(application_id, started_at DESC);
CREATE INDEX idx_deployments_status ON deployments(status);

-- Audit logs
CREATE TABLE audit_logs (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID REFERENCES users(id),
  action VARCHAR(100) NOT NULL,
  resource_type VARCHAR(50) NOT NULL,
  resource_id UUID,
  details JSONB DEFAULT '{}',
  ip_address INET,
  user_agent TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_audit_user ON audit_logs(user_id, created_at DESC);
CREATE INDEX idx_audit_resource ON audit_logs(resource_type, resource_id);
CREATE INDEX idx_audit_action ON audit_logs(action);

-- Full-text search for logs
ALTER TABLE audit_logs ADD COLUMN search_vector tsvector;
CREATE INDEX idx_audit_search ON audit_logs USING GIN (search_vector);

-- Trigger to update search vector
CREATE FUNCTION audit_logs_search_update() RETURNS trigger AS $$
BEGIN
  NEW.search_vector := to_tsvector('english', 
    COALESCE(NEW.action, '') || ' ' || 
    COALESCE(NEW.details::text, '')
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER audit_logs_search_update_trigger
BEFORE INSERT OR UPDATE ON audit_logs
FOR EACH ROW EXECUTE FUNCTION audit_logs_search_update();
```

### Prisma Schema

```prisma path=/prisma/schema.prisma start=null
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

model User {
  id           String   @id @default(uuid())
  username     String   @unique
  email        String   @unique
  passwordHash String   @map("password_hash")
  role         String   @default("user")
  createdAt    DateTime @default(now()) @map("created_at")
  updatedAt    DateTime @updatedAt @map("updated_at")

  projects     Project[]
  deployments  Deployment[]
  auditLogs    AuditLog[]

  @@index([email])
  @@index([role])
  @@map("users")
}

model Project {
  id          String   @id @default(uuid())
  name        String
  description String?
  ownerId     String   @map("owner_id")
  metadata    Json     @default("{}")
  createdAt   DateTime @default(now()) @map("created_at")
  updatedAt   DateTime @updatedAt @map("updated_at")

  owner        User          @relation(fields: [ownerId], references: [id], onDelete: Cascade)
  applications Application[]

  @@index([ownerId])
  @@map("projects")
}

model Application {
  id           String   @id @default(uuid())
  projectId    String   @map("project_id")
  name         String
  type         String
  sourceType   String?  @map("source_type")
  sourceConfig Json     @default("{}") @map("source_config")
  envVars      Json     @default("{}") @map("env_vars")
  dockerConfig Json     @default("{}") @map("docker_config")
  status       String   @default("stopped")
  createdAt    DateTime @default(now()) @map("created_at")
  updatedAt    DateTime @updatedAt @map("updated_at")

  project     Project      @relation(fields: [projectId], references: [id], onDelete: Cascade)
  deployments Deployment[]

  @@unique([projectId, name])
  @@index([projectId])
  @@index([status])
  @@map("applications")
}
```

### Connection Management

```typescript path=/lib/db.ts start=null
import { Pool } from 'pg'

const pool = new Pool({
  host: process.env.POSTGRES_HOST || 'localhost',
  port: parseInt(process.env.POSTGRES_PORT || '5432'),
  database: process.env.POSTGRES_DB || 'dokploy',
  user: process.env.POSTGRES_USER || 'dokploy',
  password: process.env.POSTGRES_PASSWORD,
  max: 20, // Maximum connections
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
})

pool.on('error', (err, client) => {
  console.error('Unexpected error on idle client', err)
})

export default pool
```

### Backup Script

```bash path=/scripts/backup-postgres.sh start=null
#!/bin/bash
set -e

BACKUP_DIR="/var/backups/dokploy"
DATE=$(date +%Y%m%d_%H%M%S)
FILENAME="dokploy_${DATE}.dump"

mkdir -p "$BACKUP_DIR"

# Dump database
docker exec dokploy-postgres pg_dump \
  -U dokploy \
  -Fc \
  -f "/tmp/${FILENAME}" \
  dokploy

# Copy from container
docker cp dokploy-postgres:/tmp/${FILENAME} "${BACKUP_DIR}/${FILENAME}"

# Cleanup old backups (keep 7 days)
find "$BACKUP_DIR" -name "dokploy_*.dump" -mtime +7 -delete

echo "Backup completed: ${BACKUP_DIR}/${FILENAME}"
```

---

## Performance Tuning

### Configuration Template (4GB RAM server)

```conf path=/postgresql.conf start=null
# Memory settings
shared_buffers = 1GB           # 25% of RAM
effective_cache_size = 3GB     # 75% of RAM
maintenance_work_mem = 256MB
work_mem = 10MB

# Checkpoint settings
checkpoint_completion_target = 0.9
wal_buffers = 16MB
default_statistics_target = 100

# Planner settings
random_page_cost = 1.1         # For SSD
effective_io_concurrency = 200 # For SSD

# Connection settings
max_connections = 100
```

---

## Monitoring

### Key Metrics

- Connection count: `SELECT count(*) FROM pg_stat_activity`
- Database size: `SELECT pg_size_pretty(pg_database_size('dokploy'))`
- Table bloat: Via pg_stat_user_tables
- Query performance: pg_stat_statements extension
- Replication lag: pg_stat_replication

---

## Related

- **ADR-002**: Next.js (uses pg client for queries)
- **ADR-004**: Redis (complementary caching layer)
- **Container Diagram**: Shows PostgreSQL as data store
- **PRD**: Data persistence and RBAC requirements

---

## References

- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [PostgreSQL JSON Functions](https://www.postgresql.org/docs/current/functions-json.html)
- [PostgreSQL Full-Text Search](https://www.postgresql.org/docs/current/textsearch.html)
- [Prisma PostgreSQL Guide](https://www.prisma.io/docs/concepts/database-connectors/postgresql)
- [PostgreSQL High Availability](https://www.postgresql.org/docs/current/high-availability.html)

---

## Decision Log

| Date | Action | Reason |
|------|--------|--------|
| 2024-12-30 | Status: Accepted | Initial architectural decision |
| Q2 2025 | Add replication guide | High-availability support |
| Q3 2025 | Evaluate TimescaleDB | If metrics volume increases significantly |

---

**Last Updated**: 2024-12-30  
**Next Review**: 2025-06-30  
**Superseded By**: None  
**Supersedes**: None
