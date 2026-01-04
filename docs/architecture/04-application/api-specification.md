# API Specification

**Document Type**: Application Architecture  
**Status**: Draft  
**Version**: 1.0  
**Last Updated**: 2024-12-30  
**Owner**: Architecture Team, API Team  

---

## Purpose

This document provides complete API specifications for Dokploy, including RESTful endpoints, request/response schemas, authentication, error handling, and versioning strategy. This serves as the canonical reference for API consumers and implementers.

---

## API Overview

**Base URL**: `https://dokploy.example.com/api`  
**Version**: v1 (current)  
**Protocol**: HTTPS only  
**Format**: JSON  
**Authentication**: JWT Bearer token or OIDC

### API Principles

1. **RESTful Design**: Resources are nouns, HTTP verbs indicate actions
2. **Idempotency**: PUT, DELETE, and GET are idempotent
3. **HATEOAS**: Responses include links to related resources
4. **Pagination**: Lists use cursor-based pagination
5. **Rate Limiting**: 100 requests/minute per user
6. **Versioning**: URL-based versioning (`/api/v1/`)

---

## Authentication

### JWT Authentication

```http
POST /api/auth/login
Content-Type: application/json

{
  "username": "admin",
  "password": "secretpassword"
}
```

**Response**:
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expiresIn": 604800,
  "user": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "username": "admin",
    "email": "admin@example.com",
    "roles": ["owner"]
  }
}
```

**Using the Token**:
```http
GET /api/applications
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### OIDC Authentication

```http
GET /api/auth/oidc/login?provider=google
```

Redirects to OIDC provider, then back to:
```http
GET /api/auth/oidc/callback?code=xxx&state=yyy
```

Returns same JWT token response as local authentication.

---

## Error Handling

### Standard Error Response

```json
{
  "error": {
    "code": "RESOURCE_NOT_FOUND",
    "message": "Application with ID 'app-123' not found",
    "details": {
      "resourceType": "application",
      "resourceId": "app-123"
    },
    "timestamp": "2024-12-30T10:00:00Z",
    "requestId": "req-abc-123"
  }
}
```

### Error Codes

| HTTP Status | Error Code | Description |
|-------------|------------|-------------|
| 400 | `VALIDATION_ERROR` | Request validation failed |
| 400 | `INVALID_INPUT` | Input data is malformed |
| 401 | `UNAUTHORIZED` | Authentication required |
| 401 | `INVALID_TOKEN` | JWT token is invalid or expired |
| 403 | `FORBIDDEN` | Insufficient permissions |
| 404 | `RESOURCE_NOT_FOUND` | Requested resource doesn't exist |
| 409 | `CONFLICT` | Resource already exists or state conflict |
| 422 | `UNPROCESSABLE_ENTITY` | Semantically incorrect request |
| 429 | `RATE_LIMIT_EXCEEDED` | Too many requests |
| 500 | `INTERNAL_SERVER_ERROR` | Unexpected server error |
| 503 | `SERVICE_UNAVAILABLE` | Service temporarily unavailable |

### Validation Errors

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Request validation failed",
    "details": {
      "errors": [
        {
          "field": "name",
          "message": "Name must be alphanumeric",
          "constraint": "regex",
          "received": "My App!"
        },
        {
          "field": "replicas",
          "message": "Replicas must be between 0 and 100",
          "constraint": "range",
          "received": 150
        }
      ]
    }
  }
}
```

---

## Pagination

### Cursor-Based Pagination

```http
GET /api/applications?limit=20&cursor=eyJpZCI6ImFwcC0xMjMifQ
```

**Response**:
```json
{
  "data": [...],
  "pagination": {
    "hasMore": true,
    "nextCursor": "eyJpZCI6ImFwcC0xNDMifQ",
    "prevCursor": null,
    "total": 145
  }
}
```

**Query Parameters**:
- `limit`: Number of items (default: 20, max: 100)
- `cursor`: Cursor for next page
- `sort`: Sort field (e.g., `createdAt`, `name`)
- `order`: Sort order (`asc` or `desc`)

---

## Rate Limiting

**Limits**:
- Anonymous: 10 requests/minute
- Authenticated: 100 requests/minute
- Webhooks: 1000 requests/hour

**Headers**:
```http
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 87
X-RateLimit-Reset: 1640000000
```

**Response when limit exceeded**:
```json
{
  "error": {
    "code": "RATE_LIMIT_EXCEEDED",
    "message": "Rate limit exceeded. Try again in 45 seconds",
    "details": {
      "limit": 100,
      "remaining": 0,
      "resetAt": "2024-12-30T10:01:00Z"
    }
  }
}
```

---

## API Endpoints

### Authentication

#### POST /api/auth/login
**Description**: Authenticate with username and password

**Request**:
```json
{
  "username": "string",
  "password": "string"
}
```

**Response**: `200 OK`
```json
{
  "token": "string",
  "expiresIn": 604800,
  "user": {
    "id": "string",
    "username": "string",
    "email": "string",
    "roles": ["string"]
  }
}
```

#### POST /api/auth/logout
**Description**: Invalidate current session

**Request**: No body required

**Response**: `204 No Content`

#### POST /api/auth/register
**Description**: Register new user

**Request**:
```json
{
  "username": "string",
  "email": "string",
  "password": "string"
}
```

**Response**: `201 Created`
```json
{
  "id": "string",
  "username": "string",
  "email": "string",
  "createdAt": "2024-12-30T10:00:00Z"
}
```

---

### Projects

#### GET /api/projects
**Description**: List all projects accessible to the user

**Query Parameters**:
- `limit` (integer): Max results (default: 20)
- `cursor` (string): Pagination cursor
- `search` (string): Search by name

**Response**: `200 OK`
```json
{
  "data": [
    {
      "id": "string",
      "name": "string",
      "description": "string",
      "ownerId": "string",
      "teamId": "string",
      "createdAt": "2024-12-30T10:00:00Z",
      "updatedAt": "2024-12-30T10:00:00Z",
      "_links": {
        "self": "/api/projects/proj-123",
        "applications": "/api/projects/proj-123/applications",
        "databases": "/api/projects/proj-123/databases"
      }
    }
  ],
  "pagination": {
    "hasMore": false,
    "nextCursor": null,
    "total": 5
  }
}
```

#### POST /api/projects
**Description**: Create new project

**Request**:
```json
{
  "name": "string (3-50 chars, alphanumeric)",
  "description": "string (optional)",
  "teamId": "string (optional)"
}
```

**Response**: `201 Created`
```json
{
  "id": "string",
  "name": "string",
  "description": "string",
  "ownerId": "string",
  "teamId": "string",
  "createdAt": "2024-12-30T10:00:00Z",
  "_links": {
    "self": "/api/projects/proj-123"
  }
}
```

#### GET /api/projects/:id
**Description**: Get project details

**Response**: `200 OK`
```json
{
  "id": "string",
  "name": "string",
  "description": "string",
  "ownerId": "string",
  "teamId": "string",
  "statistics": {
    "applicationCount": 12,
    "databaseCount": 3,
    "deploymentCount": 145
  },
  "createdAt": "2024-12-30T10:00:00Z",
  "updatedAt": "2024-12-30T10:00:00Z",
  "_links": {
    "self": "/api/projects/proj-123",
    "applications": "/api/projects/proj-123/applications",
    "databases": "/api/projects/proj-123/databases"
  }
}
```

#### PATCH /api/projects/:id
**Description**: Update project

**Request**:
```json
{
  "name": "string (optional)",
  "description": "string (optional)",
  "teamId": "string (optional)"
}
```

**Response**: `200 OK` (same schema as GET)

#### DELETE /api/projects/:id
**Description**: Delete project (soft delete)

**Response**: `204 No Content`

---

### Applications

#### GET /api/applications
**Description**: List applications

**Query Parameters**:
- `projectId` (string): Filter by project
- `status` (string): Filter by status (running, stopped, error)
- `limit` (integer): Max results
- `cursor` (string): Pagination cursor

**Response**: `200 OK`
```json
{
  "data": [
    {
      "id": "string",
      "name": "string",
      "projectId": "string",
      "image": "string",
      "status": "running",
      "replicas": 3,
      "healthStatus": "healthy",
      "lastDeployment": {
        "id": "string",
        "status": "success",
        "createdAt": "2024-12-30T10:00:00Z"
      },
      "createdAt": "2024-12-30T10:00:00Z",
      "_links": {
        "self": "/api/applications/app-123",
        "deploy": "/api/applications/app-123/deploy",
        "logs": "/api/applications/app-123/logs",
        "metrics": "/api/applications/app-123/metrics"
      }
    }
  ],
  "pagination": {
    "hasMore": true,
    "nextCursor": "eyJpZCI6ImFwcC0xMjMifQ",
    "total": 45
  }
}
```

#### POST /api/applications
**Description**: Create new application

**Request**:
```json
{
  "name": "string (3-50 chars, alphanumeric-dash)",
  "projectId": "string",
  "image": "string (Docker image)",
  "replicas": 1,
  "envVars": [
    {
      "key": "string",
      "value": "string",
      "isSecret": false
    }
  ],
  "ports": [
    {
      "containerPort": 8080,
      "protocol": "tcp"
    }
  ],
  "volumes": [
    {
      "source": "string",
      "target": "string",
      "readOnly": false
    }
  ],
  "healthCheck": {
    "command": "string",
    "interval": 30,
    "timeout": 10,
    "retries": 3
  },
  "resources": {
    "memoryLimit": 512,
    "cpuLimit": 0.5
  },
  "gitSource": {
    "repoUrl": "string",
    "branch": "main",
    "buildPath": "./",
    "dockerfile": "Dockerfile"
  }
}
```

**Response**: `201 Created`
```json
{
  "id": "string",
  "name": "string",
  "projectId": "string",
  "serviceName": "string",
  "status": "pending",
  "createdAt": "2024-12-30T10:00:00Z",
  "_links": {
    "self": "/api/applications/app-123",
    "deploy": "/api/applications/app-123/deploy"
  }
}
```

#### GET /api/applications/:id
**Description**: Get application details

**Response**: `200 OK`
```json
{
  "id": "string",
  "name": "string",
  "projectId": "string",
  "serviceName": "string",
  "image": "string",
  "status": "running",
  "replicas": 3,
  "healthStatus": "healthy",
  "envVars": [
    {
      "key": "PORT",
      "value": "8080",
      "isSecret": false
    }
  ],
  "ports": [
    {
      "containerPort": 8080,
      "protocol": "tcp",
      "publishedPort": 30001
    }
  ],
  "volumes": [
    {
      "source": "app-data",
      "target": "/data",
      "readOnly": false
    }
  ],
  "domains": [
    {
      "domain": "myapp.example.com",
      "certificateStatus": "valid",
      "expiresAt": "2025-03-30T00:00:00Z"
    }
  ],
  "resources": {
    "memoryLimit": 512,
    "cpuLimit": 0.5,
    "currentMemory": 345,
    "currentCpu": 0.23
  },
  "gitSource": {
    "repoUrl": "https://github.com/user/myapp",
    "branch": "main",
    "lastCommitSha": "abc123def456",
    "lastSync": "2024-12-30T10:00:00Z"
  },
  "createdAt": "2024-12-30T10:00:00Z",
  "updatedAt": "2024-12-30T10:00:00Z",
  "_links": {
    "self": "/api/applications/app-123",
    "deploy": "/api/applications/app-123/deploy",
    "logs": "/api/applications/app-123/logs",
    "metrics": "/api/applications/app-123/metrics",
    "deployments": "/api/applications/app-123/deployments"
  }
}
```

#### PATCH /api/applications/:id
**Description**: Update application configuration

**Request**:
```json
{
  "replicas": 5,
  "envVars": [...],
  "resources": {...}
}
```

**Response**: `200 OK` (same schema as GET)

#### DELETE /api/applications/:id
**Description**: Delete application

**Query Parameters**:
- `deleteVolumes` (boolean): Also delete associated volumes (default: false)

**Response**: `204 No Content`

#### POST /api/applications/:id/deploy
**Description**: Trigger deployment

**Request**:
```json
{
  "branch": "main (optional)",
  "commitSha": "string (optional)",
  "force": false
}
```

**Response**: `202 Accepted`
```json
{
  "deploymentId": "string",
  "status": "pending",
  "queuePosition": 2,
  "estimatedTime": 300,
  "_links": {
    "deployment": "/api/deployments/deploy-123",
    "logs": "/api/deployments/deploy-123/logs"
  }
}
```

#### GET /api/applications/:id/logs
**Description**: Get application logs

**Query Parameters**:
- `tail` (integer): Number of lines (default: 100, max: 1000)
- `since` (timestamp): Logs since timestamp
- `follow` (boolean): Stream logs (WebSocket)

**Response**: `200 OK`
```json
{
  "logs": [
    {
      "timestamp": "2024-12-30T10:00:00Z",
      "level": "info",
      "message": "Server started on port 8080",
      "container": "app-123-1"
    }
  ],
  "_links": {
    "self": "/api/applications/app-123/logs",
    "stream": "ws://dokploy.example.com/api/applications/app-123/logs?follow=true"
  }
}
```

#### GET /api/applications/:id/metrics
**Description**: Get application metrics

**Query Parameters**:
- `period` (string): Time period (1h, 6h, 24h, 7d, 30d)
- `step` (integer): Data point interval in seconds

**Response**: `200 OK`
```json
{
  "period": "1h",
  "metrics": {
    "cpu": [
      {"timestamp": "2024-12-30T10:00:00Z", "value": 0.23},
      {"timestamp": "2024-12-30T10:01:00Z", "value": 0.25}
    ],
    "memory": [
      {"timestamp": "2024-12-30T10:00:00Z", "value": 345}
    ],
    "networkRx": [
      {"timestamp": "2024-12-30T10:00:00Z", "value": 1024000}
    ],
    "networkTx": [
      {"timestamp": "2024-12-30T10:00:00Z", "value": 512000}
    ],
    "requests": [
      {"timestamp": "2024-12-30T10:00:00Z", "value": 150}
    ],
    "errors": [
      {"timestamp": "2024-12-30T10:00:00Z", "value": 2}
    ]
  }
}
```

#### POST /api/applications/:id/scale
**Description**: Scale application replicas

**Request**:
```json
{
  "replicas": 5
}
```

**Response**: `200 OK`
```json
{
  "previousReplicas": 3,
  "currentReplicas": 5,
  "status": "scaling"
}
```

#### POST /api/applications/:id/restart
**Description**: Restart application

**Response**: `202 Accepted`

---

### Deployments

#### GET /api/deployments
**Description**: List deployments

**Query Parameters**:
- `applicationId` (string): Filter by application
- `status` (string): Filter by status
- `limit` (integer): Max results
- `cursor` (string): Pagination cursor

**Response**: `200 OK`
```json
{
  "data": [
    {
      "id": "string",
      "applicationId": "string",
      "status": "success",
      "branch": "main",
      "commitSha": "abc123def456",
      "commitMessage": "Fix bug in authentication",
      "author": "John Doe",
      "duration": 245,
      "createdAt": "2024-12-30T10:00:00Z",
      "finishedAt": "2024-12-30T10:04:05Z",
      "_links": {
        "self": "/api/deployments/deploy-123",
        "application": "/api/applications/app-123",
        "logs": "/api/deployments/deploy-123/logs"
      }
    }
  ],
  "pagination": {...}
}
```

#### GET /api/deployments/:id
**Description**: Get deployment details

**Response**: `200 OK`
```json
{
  "id": "string",
  "applicationId": "string",
  "status": "success",
  "branch": "main",
  "commitSha": "abc123def456",
  "commitMessage": "Fix bug in authentication",
  "author": "John Doe",
  "buildOutput": "string",
  "stages": [
    {
      "name": "cloning",
      "status": "completed",
      "startedAt": "2024-12-30T10:00:00Z",
      "finishedAt": "2024-12-30T10:00:15Z",
      "duration": 15
    },
    {
      "name": "building",
      "status": "completed",
      "startedAt": "2024-12-30T10:00:15Z",
      "finishedAt": "2024-12-30T10:03:30Z",
      "duration": 195
    },
    {
      "name": "deploying",
      "status": "completed",
      "startedAt": "2024-12-30T10:03:30Z",
      "finishedAt": "2024-12-30T10:04:05Z",
      "duration": 35
    }
  ],
  "createdAt": "2024-12-30T10:00:00Z",
  "finishedAt": "2024-12-30T10:04:05Z",
  "_links": {
    "self": "/api/deployments/deploy-123",
    "rollback": "/api/deployments/deploy-123/rollback",
    "logs": "/api/deployments/deploy-123/logs"
  }
}
```

#### POST /api/deployments/:id/rollback
**Description**: Rollback to previous deployment

**Response**: `202 Accepted`
```json
{
  "deploymentId": "string",
  "status": "pending",
  "previousDeploymentId": "string"
}
```

#### GET /api/deployments/:id/logs
**Description**: Get deployment logs

**Response**: `200 OK`
```json
{
  "logs": [
    {
      "timestamp": "2024-12-30T10:00:00Z",
      "stage": "cloning",
      "message": "Cloning repository...",
      "level": "info"
    }
  ]
}
```

---

### Databases

#### GET /api/databases
**Description**: List databases

**Response**: `200 OK`
```json
{
  "data": [
    {
      "id": "string",
      "name": "string",
      "type": "postgresql",
      "version": "16",
      "status": "running",
      "size": 1024000000,
      "projectId": "string",
      "createdAt": "2024-12-30T10:00:00Z",
      "_links": {
        "self": "/api/databases/db-123",
        "backups": "/api/databases/db-123/backups"
      }
    }
  ]
}
```

#### POST /api/databases
**Description**: Create database

**Request**:
```json
{
  "name": "string",
  "type": "postgresql | mysql | mongodb | redis",
  "version": "string",
  "projectId": "string",
  "resources": {
    "memoryLimit": 1024,
    "storageSize": 10240
  },
  "configuration": {
    "maxConnections": 100,
    "sharedBuffers": "256MB"
  }
}
```

**Response**: `201 Created`

#### GET /api/databases/:id
**Description**: Get database details

**Response**: `200 OK`
```json
{
  "id": "string",
  "name": "string",
  "type": "postgresql",
  "version": "16",
  "status": "running",
  "connectionString": "postgresql://user:***@host:5432/dbname",
  "size": 1024000000,
  "statistics": {
    "connections": 12,
    "queries": 1500,
    "cacheHitRate": 0.95
  },
  "resources": {
    "memoryLimit": 1024,
    "storageSize": 10240,
    "currentMemory": 768,
    "currentStorage": 1024
  },
  "createdAt": "2024-12-30T10:00:00Z",
  "_links": {
    "self": "/api/databases/db-123",
    "backups": "/api/databases/db-123/backups"
  }
}
```

#### POST /api/databases/:id/backup
**Description**: Create database backup

**Request**:
```json
{
  "name": "string (optional)",
  "compress": true
}
```

**Response**: `202 Accepted`
```json
{
  "backupId": "string",
  "status": "pending"
}
```

#### GET /api/databases/:id/backups
**Description**: List database backups

**Response**: `200 OK`
```json
{
  "data": [
    {
      "id": "string",
      "name": "string",
      "size": 102400000,
      "status": "completed",
      "createdAt": "2024-12-30T10:00:00Z",
      "_links": {
        "restore": "/api/databases/db-123/backups/backup-123/restore",
        "download": "/api/databases/db-123/backups/backup-123/download"
      }
    }
  ]
}
```

#### POST /api/databases/:id/backups/:backupId/restore
**Description**: Restore database from backup

**Response**: `202 Accepted`

---

### Webhooks

#### POST /api/webhooks/github
**Description**: GitHub webhook handler

**Headers**:
- `X-GitHub-Event`: Event type
- `X-Hub-Signature-256`: HMAC signature

**Request**:
```json
{
  "ref": "refs/heads/main",
  "repository": {
    "name": "myapp",
    "full_name": "user/myapp",
    "clone_url": "https://github.com/user/myapp.git"
  },
  "commits": [
    {
      "id": "abc123def456",
      "message": "Fix bug",
      "author": {
        "name": "John Doe",
        "email": "john@example.com"
      }
    }
  ]
}
```

**Response**: `202 Accepted`
```json
{
  "deploymentId": "string",
  "status": "queued"
}
```

#### POST /api/webhooks/gitlab
**Description**: GitLab webhook handler

**Headers**:
- `X-Gitlab-Event`: Event type
- `X-Gitlab-Token`: Secret token

**Response**: `202 Accepted`

---

### Metrics

#### GET /api/metrics
**Description**: System-wide metrics

**Response**: `200 OK`
```json
{
  "system": {
    "cpu": 0.45,
    "memory": 2048,
    "disk": 10240,
    "network": {
      "rx": 1024000,
      "tx": 512000
    }
  },
  "applications": {
    "total": 45,
    "running": 42,
    "stopped": 2,
    "error": 1
  },
  "deployments": {
    "total": 1234,
    "lastHour": 12,
    "successRate": 0.95
  }
}
```

#### GET /api/metrics/prometheus
**Description**: Prometheus-compatible metrics endpoint

**Response**: `200 OK` (text/plain)
```
# HELP dokploy_applications_total Total number of applications
# TYPE dokploy_applications_total gauge
dokploy_applications_total{status="running"} 42
dokploy_applications_total{status="stopped"} 2

# HELP dokploy_deployments_total Total number of deployments
# TYPE dokploy_deployments_total counter
dokploy_deployments_total{status="success"} 1172
dokploy_deployments_total{status="failed"} 62
```

---

### Users & Teams

#### GET /api/users/me
**Description**: Get current user profile

**Response**: `200 OK`
```json
{
  "id": "string",
  "username": "string",
  "email": "string",
  "roles": ["owner"],
  "teams": [
    {
      "id": "string",
      "name": "string",
      "role": "admin"
    }
  ],
  "createdAt": "2024-12-30T10:00:00Z"
}
```

#### PATCH /api/users/me
**Description**: Update current user profile

**Request**:
```json
{
  "email": "string (optional)",
  "password": "string (optional)",
  "currentPassword": "string (required if changing password)"
}
```

**Response**: `200 OK`

#### GET /api/teams
**Description**: List teams

**Response**: `200 OK`
```json
{
  "data": [
    {
      "id": "string",
      "name": "string",
      "memberCount": 5,
      "projectCount": 12,
      "createdAt": "2024-12-30T10:00:00Z"
    }
  ]
}
```

#### POST /api/teams
**Description**: Create team

**Request**:
```json
{
  "name": "string",
  "description": "string (optional)"
}
```

**Response**: `201 Created`

#### POST /api/teams/:id/members
**Description**: Add team member

**Request**:
```json
{
  "userId": "string",
  "role": "admin | developer | viewer"
}
```

**Response**: `201 Created`

---

## WebSocket API

### Connection

```javascript
const ws = new WebSocket('wss://dokploy.example.com/api/ws?token=JWT_TOKEN');

ws.onopen = () => {
  console.log('Connected');
};

ws.onmessage = (event) => {
  const data = JSON.parse(event.data);
  console.log('Received:', data);
};
```

### Event Types

#### Deployment Status
```json
{
  "type": "deployment.status",
  "data": {
    "deploymentId": "string",
    "applicationId": "string",
    "status": "building",
    "progress": 45,
    "stage": "building",
    "message": "Installing dependencies..."
  }
}
```

#### Application Logs
```json
{
  "type": "application.logs",
  "data": {
    "applicationId": "string",
    "timestamp": "2024-12-30T10:00:00Z",
    "level": "info",
    "message": "Request completed in 45ms"
  }
}
```

#### Resource Alerts
```json
{
  "type": "resource.alert",
  "data": {
    "applicationId": "string",
    "metric": "memory",
    "threshold": 512,
    "current": 487,
    "severity": "warning"
  }
}
```

---

## SDK Examples

### JavaScript/TypeScript

```typescript
import { DokployClient } from '@dokploy/sdk';

const client = new DokployClient({
  baseUrl: 'https://dokploy.example.com',
  token: 'YOUR_JWT_TOKEN'
});

// List applications
const applications = await client.applications.list({
  projectId: 'proj-123',
  limit: 20
});

// Create application
const app = await client.applications.create({
  name: 'myapp',
  projectId: 'proj-123',
  image: 'nginx:latest',
  replicas: 3
});

// Deploy application
const deployment = await client.applications.deploy(app.id, {
  branch: 'main'
});

// Stream logs
const logStream = client.applications.logs(app.id, { follow: true });
logStream.on('data', (log) => {
  console.log(log.message);
});
```

### Python

```python
from dokploy import DokployClient

client = DokployClient(
    base_url='https://dokploy.example.com',
    token='YOUR_JWT_TOKEN'
)

# List applications
applications = client.applications.list(
    project_id='proj-123',
    limit=20
)

# Create application
app = client.applications.create(
    name='myapp',
    project_id='proj-123',
    image='nginx:latest',
    replicas=3
)

# Deploy application
deployment = client.applications.deploy(
    app.id,
    branch='main'
)

# Stream logs
for log in client.applications.logs(app.id, follow=True):
    print(log.message)
```

### cURL

```bash
# Login
curl -X POST https://dokploy.example.com/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"secret"}'

# List applications
curl https://dokploy.example.com/api/applications \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"

# Create application
curl -X POST https://dokploy.example.com/api/applications \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "myapp",
    "projectId": "proj-123",
    "image": "nginx:latest",
    "replicas": 3
  }'

# Deploy application
curl -X POST https://dokploy.example.com/api/applications/app-123/deploy \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"branch":"main"}'
```

---

## API Versioning

### Current Version
- **v1** (current, stable)

### Version Strategy
- **URL-based versioning**: `/api/v1/`, `/api/v2/`
- **Backward compatibility**: Maintained for 12 months after deprecation
- **Breaking changes**: Only in major versions
- **Deprecation warnings**: Via `X-Deprecated` header

### Deprecation Header
```http
X-Deprecated: true
X-Deprecated-Version: v1
X-Sunset: 2025-12-31
X-Migration-Guide: https://docs.dokploy.com/api/migration-v2
```

---

## Rate Limiting Details

### Rate Limit Algorithms
- **Token Bucket**: Standard endpoints
- **Sliding Window**: Burst protection
- **Per-user**: Based on authentication

### Rate Limit Tiers

| Tier | Requests/min | Burst | Webhooks/hour |
|------|--------------|-------|---------------|
| Anonymous | 10 | 20 | 0 |
| Authenticated | 100 | 150 | 1000 |
| Premium | 500 | 1000 | 10000 |

### Rate Limit Headers
```http
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 87
X-RateLimit-Reset: 1640000000
X-RateLimit-Used: 13
```

---

## Security

### HTTPS Only
All API requests must use HTTPS. HTTP requests are rejected with `301` redirect.

### Authentication Methods
1. **JWT Bearer Token** (recommended for API clients)
2. **OIDC** (recommended for user authentication)
3. **API Keys** (planned for v2)

### CORS Configuration
```http
Access-Control-Allow-Origin: https://app.dokploy.com
Access-Control-Allow-Methods: GET, POST, PUT, PATCH, DELETE
Access-Control-Allow-Headers: Authorization, Content-Type
Access-Control-Max-Age: 3600
```

### Security Headers
```http
Strict-Transport-Security: max-age=31536000; includeSubDomains
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
X-XSS-Protection: 1; mode=block
Content-Security-Policy: default-src 'self'
```

---

## OpenAPI Specification

**OpenAPI Version**: 3.1.0  
**Specification URL**: `https://dokploy.example.com/api/openapi.json`

### Swagger UI
Available at: `https://dokploy.example.com/api/docs`

### Redoc
Available at: `https://dokploy.example.com/api/redoc`

---

## Related Documents

- **Component Diagram**: Application architecture and components
- **Data Model**: Database schemas and entity relationships
- **Security View**: Authentication, authorization, and encryption
- **Data Flow Diagram**: Request/response flows and data transformations

---

**Document Version**: 1.0  
**Last Updated**: 2024-12-30  
**Next Review**: 2025-03-30  
**Reviewed By**: Architecture Team, API Team, Security Team
