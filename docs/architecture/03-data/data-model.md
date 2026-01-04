# Data Model

**Document Type**: Data Architecture  
**Status**: Draft  
**Version**: 1.0  
**Last Updated**: 2024-12-30  
**Owner**: Architecture Team  

---

## Purpose

This document defines the logical data model for Dokploy, including entities, relationships, attributes, and constraints. The data model serves as the blueprint for the PostgreSQL database schema and ensures data integrity and consistency across the platform.

---

## Entity-Relationship Diagram

```mermaid
erDiagram
    USER ||--o{ PROJECT : owns
    USER ||--o{ TEAM_MEMBER : "member of"
    USER ||--o{ DEPLOYMENT : triggers
    USER ||--o{ AUDIT_LOG : performs
    
    TEAM ||--o{ TEAM_MEMBER : has
    TEAM ||--o{ PROJECT : manages
    
    PROJECT ||--o{ APPLICATION : contains
    PROJECT ||--o{ DATABASE : contains
    PROJECT ||--o{ DOMAIN : uses
    
    APPLICATION ||--o{ DEPLOYMENT : has
    APPLICATION ||--o{ ENV_VAR : configures
    APPLICATION ||--o{ VOLUME : mounts
    APPLICATION ||--||  GIT_SOURCE : "sourced from"
    
    DATABASE ||--o{ BACKUP : has
    DATABASE ||--o{ VOLUME : uses
    
    DEPLOYMENT ||--o{ DEPLOYMENT_LOG : generates
    
    DOMAIN ||--o{ CERTIFICATE : secured_by
    
    USER {
        uuid id PK
        string username UK
        string email UK
        string password_hash
        string role
        jsonb preferences
        timestamp created_at
        timestamp updated_at
    }
    
    TEAM {
        uuid id PK
        string name
        string description
        jsonb settings
        timestamp created_at
    }
    
    TEAM_MEMBER {
        uuid id PK
        uuid user_id FK
        uuid team_id FK
        string role
        timestamp joined_at
    }
    
    PROJECT {
        uuid id PK
        string name
        string description
        uuid owner_id FK
        uuid team_id FK
        jsonb metadata
        timestamp created_at
        timestamp updated_at
    }
    
    APPLICATION {
        uuid id PK
        uuid project_id FK
        string name UK
        string type
        string status
        string source_type
        jsonb source_config
        jsonb docker_config
        jsonb env_vars
        int replicas
        timestamp created_at
        timestamp updated_at
    }
    
    GIT_SOURCE {
        uuid id PK
        uuid application_id FK
        string provider
        string repository
        string branch
        string commit_sha
        jsonb webhook_config
    }
    
    DATABASE {
        uuid id PK
        uuid project_id FK
        string name UK
        string type
        string status
        string version
        jsonb config
        string connection_string
        timestamp created_at
    }
    
    DEPLOYMENT {
        uuid id PK
        uuid application_id FK
        uuid triggered_by FK
        string status
        string commit_sha
        text logs
        jsonb metadata
        timestamp started_at
        timestamp completed_at
    }
    
    DEPLOYMENT_LOG {
        bigint id PK
        uuid deployment_id FK
        string level
        text message
        timestamp created_at
    }
    
    ENV_VAR {
        uuid id PK
        uuid application_id FK
        string key
        string value
        boolean is_secret
        timestamp created_at
    }
    
    VOLUME {
        uuid id PK
        string name UK
        string type
        string mount_path
        int size_gb
        timestamp created_at
    }
    
    DOMAIN {
        uuid id PK
        uuid project_id FK
        string domain UK
        string target_type
        uuid target_id
        boolean tls_enabled
        timestamp created_at
    }
    
    CERTIFICATE {
        uuid id PK
        uuid domain_id FK
        string issuer
        text certificate
        text private_key
        timestamp expires_at
        timestamp created_at
    }
    
    BACKUP {
        uuid id PK
        uuid database_id FK
        string type
        string status
        string storage_path
        bigint size_bytes
        timestamp created_at
        timestamp completed_at
    }
    
    AUDIT_LOG {
        bigint id PK
        uuid user_id FK
        string action
        string resource_type
        uuid resource_id
        jsonb details
        inet ip_address
        text user_agent
        timestamp created_at
    }
```

---

## Core Entities

### USER

**Description**: Platform users who can manage applications and resources.

**Attributes**:
- `id` (UUID, PK): Unique identifier
- `username` (VARCHAR(255), UK): Unique username
- `email` (VARCHAR(255), UK): Email address (unique)
- `password_hash` (VARCHAR(255)): Bcrypt hashed password
- `role` (VARCHAR(50)): User role (super_admin, admin, developer, viewer)
- `preferences` (JSONB): User preferences (theme, notifications, etc.)
- `created_at` (TIMESTAMPTZ): Account creation timestamp
- `updated_at` (TIMESTAMPTZ): Last update timestamp

**Constraints**:
- `username` must be unique and match regex `^[a-z0-9_-]{3,50}$`
- `email` must be valid email format
- `role` must be one of: super_admin, admin, developer, viewer
- `password_hash` required unless using SSO

**Indexes**:
- Primary key on `id`
- Unique index on `username`
- Unique index on `email`
- Index on `role`

**Sample Data**:
```sql
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "username": "john_doe",
  "email": "john@example.com",
  "password_hash": "$2b$12$...",
  "role": "developer",
  "preferences": {
    "theme": "dark",
    "notifications": {
      "email": true,
      "browser": false
    }
  },
  "created_at": "2024-01-15T10:30:00Z",
  "updated_at": "2024-12-30T14:00:00Z"
}
```

---

### TEAM

**Description**: Groups of users who collaborate on projects.

**Attributes**:
- `id` (UUID, PK): Unique identifier
- `name` (VARCHAR(255), UK): Team name
- `description` (TEXT): Team description
- `settings` (JSONB): Team-specific settings
- `created_at` (TIMESTAMPTZ): Team creation timestamp

**Constraints**:
- `name` must be unique within platform
- `name` length 3-100 characters

**Indexes**:
- Primary key on `id`
- Unique index on `name`

---

### TEAM_MEMBER

**Description**: Join table linking users to teams with roles.

**Attributes**:
- `id` (UUID, PK): Unique identifier
- `user_id` (UUID, FK→USER): User reference
- `team_id` (UUID, FK→TEAM): Team reference
- `role` (VARCHAR(50)): Role in team (owner, admin, member, viewer)
- `joined_at` (TIMESTAMPTZ): Membership start timestamp

**Constraints**:
- `(user_id, team_id)` must be unique (user can only join team once)
- `role` must be one of: owner, admin, member, viewer
- At least one owner per team

**Indexes**:
- Primary key on `id`
- Unique index on `(user_id, team_id)`
- Index on `team_id`

---

### PROJECT

**Description**: Logical grouping of related applications and databases.

**Attributes**:
- `id` (UUID, PK): Unique identifier
- `name` (VARCHAR(255)): Project name
- `description` (TEXT): Project description
- `owner_id` (UUID, FK→USER): Project owner
- `team_id` (UUID, FK→TEAM, nullable): Associated team
- `metadata` (JSONB): Additional project metadata (tags, labels, etc.)
- `created_at` (TIMESTAMPTZ): Project creation timestamp
- `updated_at` (TIMESTAMPTZ): Last update timestamp

**Constraints**:
- `(owner_id, name)` must be unique (user can't have duplicate project names)
- `name` length 3-100 characters

**Indexes**:
- Primary key on `id`
- Index on `owner_id`
- Index on `team_id`
- Unique index on `(owner_id, name)`
- GIN index on `metadata`

**Sample Data**:
```sql
{
  "id": "660f9500-f39c-41d4-a716-446655440001",
  "name": "my-saas-app",
  "description": "Production SaaS application",
  "owner_id": "550e8400-e29b-41d4-a716-446655440000",
  "team_id": "770fa600-g49d-41d4-a716-446655440002",
  "metadata": {
    "environment": "production",
    "tags": ["critical", "customer-facing"],
    "cost_center": "engineering"
  },
  "created_at": "2024-06-01T08:00:00Z",
  "updated_at": "2024-12-30T14:00:00Z"
}
```

---

### APPLICATION

**Description**: Deployed application or service.

**Attributes**:
- `id` (UUID, PK): Unique identifier
- `project_id` (UUID, FK→PROJECT): Parent project
- `name` (VARCHAR(255), UK): Application name
- `type` (VARCHAR(50)): Application type (docker, git, compose)
- `status` (VARCHAR(50)): Current status (running, stopped, deploying, failed)
- `source_type` (VARCHAR(50)): Source type (github, gitlab, docker, docker_compose)
- `source_config` (JSONB): Source-specific configuration
- `docker_config` (JSONB): Docker/Swarm configuration
- `env_vars` (JSONB): Environment variables (non-sensitive)
- `replicas` (INT): Number of replicas
- `created_at` (TIMESTAMPTZ): Application creation timestamp
- `updated_at` (TIMESTAMPTZ): Last update timestamp

**Constraints**:
- `(project_id, name)` must be unique
- `type` must be one of: docker, git, compose
- `status` must be one of: stopped, deploying, running, failed, scaling
- `replicas` must be >= 0

**Indexes**:
- Primary key on `id`
- Index on `project_id`
- Index on `status`
- Unique index on `(project_id, name)`
- GIN index on `env_vars`
- GIN index on `docker_config`

**Sample Data**:
```sql
{
  "id": "880ga700-h59e-41d4-a716-446655440003",
  "project_id": "660f9500-f39c-41d4-a716-446655440001",
  "name": "api-service",
  "type": "git",
  "status": "running",
  "source_type": "github",
  "source_config": {
    "repository": "mycompany/api-service",
    "branch": "main",
    "build_context": ".",
    "dockerfile": "Dockerfile"
  },
  "docker_config": {
    "image": "registry.dokploy.internal/api-service:latest",
    "ports": [{"container": 8080, "host": 8080}],
    "networks": ["dokploy-app"],
    "healthcheck": {
      "test": ["CMD", "curl", "-f", "http://localhost:8080/health"],
      "interval": "30s",
      "timeout": "5s",
      "retries": 3
    },
    "resources": {
      "limits": {"memory": "512M", "cpus": "0.5"},
      "reservations": {"memory": "256M"}
    }
  },
  "env_vars": {
    "NODE_ENV": "production",
    "PORT": "8080",
    "API_VERSION": "v1"
  },
  "replicas": 3,
  "created_at": "2024-06-15T09:00:00Z",
  "updated_at": "2024-12-30T10:00:00Z"
}
```

---

### GIT_SOURCE

**Description**: Git repository configuration for applications.

**Attributes**:
- `id` (UUID, PK): Unique identifier
- `application_id` (UUID, FK→APPLICATION, UK): Associated application
- `provider` (VARCHAR(50)): Git provider (github, gitlab, bitbucket)
- `repository` (VARCHAR(500)): Repository path
- `branch` (VARCHAR(255)): Target branch
- `commit_sha` (VARCHAR(40)): Latest deployed commit
- `webhook_config` (JSONB): Webhook configuration and secrets

**Constraints**:
- `application_id` is unique (one-to-one with application)
- `provider` must be one of: github, gitlab, bitbucket, gitea

**Indexes**:
- Primary key on `id`
- Unique index on `application_id`

---

### DATABASE

**Description**: Managed database instance.

**Attributes**:
- `id` (UUID, PK): Unique identifier
- `project_id` (UUID, FK→PROJECT): Parent project
- `name` (VARCHAR(255), UK): Database name
- `type` (VARCHAR(50)): Database type (postgresql, mysql, mongodb, redis)
- `status` (VARCHAR(50)): Current status (running, stopped, initializing, failed)
- `version` (VARCHAR(50)): Database version
- `config` (JSONB): Database-specific configuration
- `connection_string` (TEXT): Connection string (encrypted)
- `created_at` (TIMESTAMPTZ): Database creation timestamp

**Constraints**:
- `(project_id, name)` must be unique
- `type` must be one of: postgresql, mysql, mongodb, redis
- `status` must be one of: initializing, running, stopped, failed

**Indexes**:
- Primary key on `id`
- Index on `project_id`
- Index on `type`
- Unique index on `(project_id, name)`

**Sample Data**:
```sql
{
  "id": "990hb800-i69f-41d4-a716-446655440004",
  "project_id": "660f9500-f39c-41d4-a716-446655440001",
  "name": "app-postgres",
  "type": "postgresql",
  "status": "running",
  "version": "16.1",
  "config": {
    "max_connections": 100,
    "shared_buffers": "256MB",
    "work_mem": "4MB",
    "persistent": true,
    "volume_size": "10GB"
  },
  "connection_string": "postgresql://dokploy:***@app-postgres:5432/app_db",
  "created_at": "2024-06-10T08:30:00Z"
}
```

---

### DEPLOYMENT

**Description**: Deployment execution record.

**Attributes**:
- `id` (UUID, PK): Unique identifier
- `application_id` (UUID, FK→APPLICATION): Target application
- `triggered_by` (UUID, FK→USER): User who triggered deployment
- `status` (VARCHAR(50)): Deployment status
- `commit_sha` (VARCHAR(40)): Deployed commit (if git-based)
- `logs` (TEXT): Deployment logs
- `metadata` (JSONB): Additional deployment metadata
- `started_at` (TIMESTAMPTZ): Deployment start time
- `completed_at` (TIMESTAMPTZ, nullable): Deployment completion time

**Constraints**:
- `status` must be one of: pending, building, deploying, success, failed, rolled_back

**Indexes**:
- Primary key on `id`
- Index on `application_id, started_at DESC`
- Index on `status`
- Index on `triggered_by`

**Sample Data**:
```sql
{
  "id": "aa0ic900-j79g-41d4-a716-446655440005",
  "application_id": "880ga700-h59e-41d4-a716-446655440003",
  "triggered_by": "550e8400-e29b-41d4-a716-446655440000",
  "status": "success",
  "commit_sha": "abc123def456",
  "logs": "Building image...\nPushing to registry...\nUpdating service...\nDeployment complete.",
  "metadata": {
    "duration_seconds": 125,
    "image_size_mb": 450,
    "build_cache_hit": true
  },
  "started_at": "2024-12-30T10:00:00Z",
  "completed_at": "2024-12-30T10:02:05Z"
}
```

---

### DEPLOYMENT_LOG

**Description**: Structured deployment log entries.

**Attributes**:
- `id` (BIGSERIAL, PK): Auto-incrementing identifier
- `deployment_id` (UUID, FK→DEPLOYMENT): Parent deployment
- `level` (VARCHAR(20)): Log level (debug, info, warn, error)
- `message` (TEXT): Log message
- `created_at` (TIMESTAMPTZ): Log timestamp

**Indexes**:
- Primary key on `id`
- Index on `(deployment_id, created_at DESC)`
- Index on `level`

---

### ENV_VAR

**Description**: Application environment variables (including secrets).

**Attributes**:
- `id` (UUID, PK): Unique identifier
- `application_id` (UUID, FK→APPLICATION): Associated application
- `key` (VARCHAR(255)): Variable name
- `value` (TEXT): Variable value (encrypted if secret)
- `is_secret` (BOOLEAN): Whether this is a secret
- `created_at` (TIMESTAMPTZ): Creation timestamp

**Constraints**:
- `(application_id, key)` must be unique
- `key` must match regex `^[A-Z_][A-Z0-9_]*$`

**Indexes**:
- Primary key on `id`
- Index on `application_id`
- Unique index on `(application_id, key)`

---

### VOLUME

**Description**: Persistent storage volumes.

**Attributes**:
- `id` (UUID, PK): Unique identifier
- `name` (VARCHAR(255), UK): Volume name
- `type` (VARCHAR(50)): Volume type (docker_volume, nfs, s3)
- `mount_path` (VARCHAR(500)): Container mount path
- `size_gb` (INT): Volume size in GB
- `created_at` (TIMESTAMPTZ): Creation timestamp

**Constraints**:
- `name` must be unique (Docker volume names are globally unique)
- `size_gb` must be > 0

**Indexes**:
- Primary key on `id`
- Unique index on `name`

---

### DOMAIN

**Description**: Custom domains and routing configuration.

**Attributes**:
- `id` (UUID, PK): Unique identifier
- `project_id` (UUID, FK→PROJECT): Parent project
- `domain` (VARCHAR(255), UK): Domain name
- `target_type` (VARCHAR(50)): Target type (application, database)
- `target_id` (UUID): Target resource ID
- `tls_enabled` (BOOLEAN): Whether TLS is enabled
- `created_at` (TIMESTAMPTZ): Creation timestamp

**Constraints**:
- `domain` must be unique (globally)
- `domain` must be valid domain format
- `target_type` must be one of: application, database

**Indexes**:
- Primary key on `id`
- Unique index on `domain`
- Index on `project_id`
- Index on `(target_type, target_id)`

---

### CERTIFICATE

**Description**: TLS/SSL certificates for domains.

**Attributes**:
- `id` (UUID, PK): Unique identifier
- `domain_id` (UUID, FK→DOMAIN): Associated domain
- `issuer` (VARCHAR(255)): Certificate issuer (Let's Encrypt, etc.)
- `certificate` (TEXT): Certificate (PEM format)
- `private_key` (TEXT): Private key (encrypted, PEM format)
- `expires_at` (TIMESTAMPTZ): Certificate expiration
- `created_at` (TIMESTAMPTZ): Certificate issue timestamp

**Constraints**:
- `expires_at` must be in future

**Indexes**:
- Primary key on `id`
- Index on `domain_id`
- Index on `expires_at` (for renewal monitoring)

---

### BACKUP

**Description**: Database backup records.

**Attributes**:
- `id` (UUID, PK): Unique identifier
- `database_id` (UUID, FK→DATABASE): Source database
- `type` (VARCHAR(50)): Backup type (full, incremental, snapshot)
- `status` (VARCHAR(50)): Backup status (pending, running, success, failed)
- `storage_path` (VARCHAR(500)): Storage location
- `size_bytes` (BIGINT): Backup size
- `created_at` (TIMESTAMPTZ): Backup start time
- `completed_at` (TIMESTAMPTZ, nullable): Backup completion time

**Constraints**:
- `type` must be one of: full, incremental, snapshot
- `status` must be one of: pending, running, success, failed

**Indexes**:
- Primary key on `id`
- Index on `database_id, created_at DESC`
- Index on `status`

---

### AUDIT_LOG

**Description**: Comprehensive audit trail of all platform actions.

**Attributes**:
- `id` (BIGSERIAL, PK): Auto-incrementing identifier
- `user_id` (UUID, FK→USER, nullable): Acting user
- `action` (VARCHAR(100)): Action performed
- `resource_type` (VARCHAR(50)): Resource type affected
- `resource_id` (UUID, nullable): Resource identifier
- `details` (JSONB): Action details
- `ip_address` (INET): Client IP address
- `user_agent` (TEXT): Client user agent
- `created_at` (TIMESTAMPTZ): Action timestamp

**Constraints**:
- `resource_type` must be one of: user, team, project, application, database, deployment, domain

**Indexes**:
- Primary key on `id`
- Index on `(user_id, created_at DESC)`
- Index on `(resource_type, resource_id)`
- Index on `action`
- Index on `created_at DESC`

**Sample Data**:
```sql
{
  "id": 1523456,
  "user_id": "550e8400-e29b-41d4-a716-446655440000",
  "action": "application.deploy",
  "resource_type": "application",
  "resource_id": "880ga700-h59e-41d4-a716-446655440003",
  "details": {
    "commit_sha": "abc123def456",
    "deployment_id": "aa0ic900-j79g-41d4-a716-446655440005",
    "replicas": 3
  },
  "ip_address": "192.168.1.100",
  "user_agent": "Mozilla/5.0 ...",
  "created_at": "2024-12-30T10:00:00Z"
}
```

---

## Relationships

### One-to-Many Relationships

| Parent | Child | Relationship | Cascade |
|--------|-------|--------------|---------|
| USER | PROJECT | owns | CASCADE |
| USER | DEPLOYMENT | triggers | SET NULL |
| USER | AUDIT_LOG | performs | SET NULL |
| TEAM | TEAM_MEMBER | has | CASCADE |
| TEAM | PROJECT | manages | SET NULL |
| PROJECT | APPLICATION | contains | CASCADE |
| PROJECT | DATABASE | contains | CASCADE |
| PROJECT | DOMAIN | uses | CASCADE |
| APPLICATION | DEPLOYMENT | has | CASCADE |
| APPLICATION | ENV_VAR | configures | CASCADE |
| APPLICATION | VOLUME | mounts | RESTRICT |
| DATABASE | BACKUP | has | CASCADE |
| DATABASE | VOLUME | uses | RESTRICT |
| DEPLOYMENT | DEPLOYMENT_LOG | generates | CASCADE |
| DOMAIN | CERTIFICATE | secured_by | CASCADE |

### One-to-One Relationships

| Parent | Child | Relationship |
|--------|-------|--------------|
| APPLICATION | GIT_SOURCE | sourced from |

### Many-to-Many Relationships

| Entity A | Entity B | Join Table | Relationship |
|----------|----------|------------|--------------|
| USER | TEAM | TEAM_MEMBER | member of |

---

## Data Constraints

### Referential Integrity

All foreign key relationships enforce referential integrity with appropriate cascade rules:

**CASCADE**: Child records deleted when parent deleted
- PROJECT → APPLICATION
- APPLICATION → DEPLOYMENT
- DATABASE → BACKUP

**SET NULL**: Foreign key set to NULL when parent deleted
- USER → DEPLOYMENT (preserve deployment history)
- USER → AUDIT_LOG (preserve audit trail)

**RESTRICT**: Prevent parent deletion if children exist
- APPLICATION → VOLUME (volumes must be explicitly managed)
- DATABASE → VOLUME

### Check Constraints

```sql
-- User constraints
ALTER TABLE users ADD CONSTRAINT check_username_format 
  CHECK (username ~ '^[a-z0-9_-]{3,50}$');

ALTER TABLE users ADD CONSTRAINT check_email_format 
  CHECK (email ~ '^[^@]+@[^@]+\.[^@]+$');

-- Application constraints
ALTER TABLE applications ADD CONSTRAINT check_replicas_non_negative 
  CHECK (replicas >= 0);

-- Volume constraints
ALTER TABLE volumes ADD CONSTRAINT check_size_positive 
  CHECK (size_gb > 0);

-- Certificate constraints
ALTER TABLE certificates ADD CONSTRAINT check_expiry_future 
  CHECK (expires_at > NOW());
```

### Enum Constraints

```sql
-- User roles
ALTER TABLE users ADD CONSTRAINT check_user_role 
  CHECK (role IN ('super_admin', 'admin', 'developer', 'viewer'));

-- Application types
ALTER TABLE applications ADD CONSTRAINT check_app_type 
  CHECK (type IN ('docker', 'git', 'compose'));

-- Application status
ALTER TABLE applications ADD CONSTRAINT check_app_status 
  CHECK (status IN ('stopped', 'deploying', 'running', 'failed', 'scaling'));

-- Database types
ALTER TABLE databases ADD CONSTRAINT check_db_type 
  CHECK (type IN ('postgresql', 'mysql', 'mongodb', 'redis'));

-- Deployment status
ALTER TABLE deployments ADD CONSTRAINT check_deployment_status 
  CHECK (status IN ('pending', 'building', 'deploying', 'success', 'failed', 'rolled_back'));
```

---

## Data Security

### Encryption

**At Rest**:
- `users.password_hash`: Bcrypt (cost 12)
- `env_vars.value` (when `is_secret=true`): AES-256-GCM
- `certificates.private_key`: AES-256-GCM
- `databases.connection_string`: AES-256-GCM

**In Transit**:
- All database connections use TLS (`sslmode=require`)
- API requests use HTTPS only

### Row-Level Security (RLS)

```sql
-- Enable RLS on projects
ALTER TABLE projects ENABLE ROW LEVEL SECURITY;

-- Users can view projects they own or are team members of
CREATE POLICY projects_select_policy ON projects
  FOR SELECT
  USING (
    owner_id = current_setting('app.user_id')::uuid
    OR team_id IN (
      SELECT team_id FROM team_members 
      WHERE user_id = current_setting('app.user_id')::uuid
    )
  );

-- Only owners can delete projects
CREATE POLICY projects_delete_policy ON projects
  FOR DELETE
  USING (owner_id = current_setting('app.user_id')::uuid);
```

---

## Data Retention

### Retention Policies

| Entity | Retention Period | Archival Strategy |
|--------|------------------|-------------------|
| DEPLOYMENT | 90 days | Archive to S3, keep metadata |
| DEPLOYMENT_LOG | 30 days | Delete automatically |
| AUDIT_LOG | 1 year (compliance) | Archive to cold storage |
| BACKUP | 7 days (daily), 4 weeks (weekly) | Rotate automatically |
| APPLICATION | Indefinite | Soft delete (status=archived) |

### Soft Delete Pattern

```sql
-- Add deleted_at column for soft deletes
ALTER TABLE applications ADD COLUMN deleted_at TIMESTAMPTZ DEFAULT NULL;

-- Index for excluding deleted records
CREATE INDEX idx_applications_active ON applications(id) 
  WHERE deleted_at IS NULL;

-- Soft delete function
CREATE FUNCTION soft_delete_application(app_id UUID) RETURNS VOID AS $$
BEGIN
  UPDATE applications 
  SET deleted_at = NOW(), status = 'archived'
  WHERE id = app_id;
END;
$$ LANGUAGE plpgsql;
```

---

## Data Migration

### Schema Version Control

Using Prisma Migrate for schema versioning:

```prisma
// prisma/schema.prisma
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

// Schema definition matches entity model above
```

### Migration Strategy

1. **Development**: Create migration with `prisma migrate dev`
2. **Staging**: Apply with `prisma migrate deploy`
3. **Production**: Review SQL, apply during maintenance window
4. **Rollback**: Maintain rollback scripts for each migration

---

## Performance Optimization

### Partitioning Strategy

**AUDIT_LOG**: Partition by month (time-series data)
```sql
CREATE TABLE audit_logs (
  -- columns as defined above
) PARTITION BY RANGE (created_at);

CREATE TABLE audit_logs_2024_12 PARTITION OF audit_logs
  FOR VALUES FROM ('2024-12-01') TO ('2025-01-01');

-- Automated partition creation via cron
```

**DEPLOYMENT_LOG**: Partition by deployment_id
```sql
CREATE TABLE deployment_logs (
  -- columns as defined above
) PARTITION BY HASH (deployment_id);

-- Create 4 partitions
CREATE TABLE deployment_logs_0 PARTITION OF deployment_logs
  FOR VALUES WITH (MODULUS 4, REMAINDER 0);
```

### Materialized Views

```sql
-- Application status summary
CREATE MATERIALIZED VIEW application_stats AS
SELECT 
  project_id,
  COUNT(*) as total_applications,
  COUNT(*) FILTER (WHERE status = 'running') as running,
  COUNT(*) FILTER (WHERE status = 'stopped') as stopped,
  COUNT(*) FILTER (WHERE status = 'failed') as failed
FROM applications
WHERE deleted_at IS NULL
GROUP BY project_id;

CREATE UNIQUE INDEX ON application_stats(project_id);

-- Refresh strategy
REFRESH MATERIALIZED VIEW CONCURRENTLY application_stats;
```

---

## Related Documents

- **ADR-003**: PostgreSQL selection decision
- **Security View**: Data security and encryption strategies
- **Container Diagram**: How data flows through components
- **API Specification**: API endpoints that interact with this data model

---

**Document Version**: 1.0  
**Last Updated**: 2024-12-30  
**Next Review**: 2025-03-30  
**Reviewed By**: Architecture Team, Database Team
