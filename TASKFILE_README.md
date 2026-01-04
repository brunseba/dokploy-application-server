# Taskfile - Task Runner for Dokploy

This project uses [Task](https://taskfile.dev/) as a task runner to wrap all scripts and common operations.

## Installation

### macOS

```bash
# Using Homebrew
brew install go-task/tap/go-task

# Or using MacPorts
sudo port install go-task
```

### Linux

```bash
# Using snap
sudo snap install task --classic

# Or using binary
sh -c "$(curl --location https://taskfile.dev/install.sh)" -- -d -b /usr/local/bin
```

### Verify Installation

```bash
task --version
```

## Quick Start

```bash
# Show all available tasks
task

# Show detailed help
task help

# Run setup (install dependencies)
task setup

# Start documentation server
task docs:serve
```

## Task Categories

### 📚 Documentation

| Task | Description |
|------|-------------|
| `task docs:serve` | Serve documentation locally with hot-reload |
| `task docs:build` | Build documentation site |
| `task docs:build:strict` | Build with strict mode (warnings as errors) |
| `task docs:deploy` | Deploy documentation to GitHub Pages |
| `task docs:pdf` | Build documentation with PDF export |
| `task docs:clean` | Clean generated documentation |
| `task docs:generate` | Generate missing documentation files |
| `task docs:check` | Check documentation for broken links |

**Examples:**
```bash
# Start local docs server
task docs:serve

# Build and deploy to GitHub Pages
task docs:build
task docs:deploy

# Generate PDF documentation
task docs:pdf
```

### 🔧 Traefik Configuration

| Task | Description |
|------|-------------|
| `task traefik:create` | Create and deploy Traefik service with Docker Swarm |
| `task traefik:configure` | Configure Traefik with OVH DNS (interactive) |
| `task traefik:configure:dry-run` | Test configuration (dry-run mode) |
| `task traefik:logs` | Show Traefik logs |
| `task traefik:logs:follow` | Follow Traefik logs in real-time |
| `task traefik:logs:acme` | Show ACME certificate logs |
| `task traefik:restart` | Restart Traefik container |
| `task traefik:status` | Check Traefik status |
| `task traefik:config:show` | Show Traefik configuration |
| `task traefik:backup` | Backup configuration and certificates |

**Examples:**
```bash
# Create Traefik service (first time setup)
task traefik:create

# Configure Traefik (interactive prompts for credentials)
task traefik:configure

# Test configuration without applying
task traefik:configure:dry-run

# Check status and logs
task traefik:status
task traefik:logs:acme

# Backup before making changes
task traefik:backup
```

### 🐳 Docker & Dokploy

| Task | Description |
|------|-------------|
| `task docker:services` | List all Docker Swarm services |
| `task docker:ps` | List all running containers |
| `task docker:logs:dokploy` | Show Dokploy service logs |
| `task docker:logs:postgres` | Show PostgreSQL logs |
| `task docker:logs:redis` | Show Redis logs |
| `task docker:stats` | Show container resource usage |
| `task docker:cleanup` | Clean up unused Docker resources |
| `task docker:cleanup:all` | Clean up ALL resources (including volumes) |

**Examples:**
```bash
# View all services
task docker:services

# Check resource usage
task docker:stats

# View logs with tail
task docker:logs:dokploy -- --tail 100

# Clean up unused resources
task docker:cleanup
```

### 💾 Database Operations

| Task | Description |
|------|-------------|
| `task db:backup` | Backup PostgreSQL database |
| `task db:restore` | Restore PostgreSQL database from backup |
| `task db:connect` | Connect to PostgreSQL database |

**Examples:**
```bash
# Create backup
task db:backup

# Restore from backup (interactive)
task db:restore

# Connect to database
task db:connect
```

### 📊 Monitoring

| Task | Description |
|------|-------------|
| `task monitor:status` | Show overall system status |
| `task monitor:health` | Check health of all services |

**Examples:**
```bash
# Quick status check
task monitor:status

# Detailed health check
task monitor:health
```

### 🛠️ Development

| Task | Description |
|------|-------------|
| `task dev:install` | Install all development dependencies |
| `task dev:check` | Run all checks (docs build, links, etc.) |
| `task setup` | Initial setup - install deps and check config |

**Examples:**
```bash
# Initial setup
task setup

# Install only docs dependencies
task dev:install

# Run all checks
task dev:check
```

### 🧪 Testing

| Task | Description |
|------|-------------|
| `task test:docs` | Test documentation build |
| `task test:scripts` | Test all scripts for syntax errors |
| `task test:all` | Run all tests |

**Examples:**
```bash
# Test everything
task test:all

# Test only documentation
task test:docs

# Check script syntax
task test:scripts
```

### 🔍 Utility Tasks

| Task | Description |
|------|-------------|
| `task version` | Show versions of all components |
| `task help` | Show detailed help for common tasks |
| `task git:status` | Show git status and recent commits |
| `task git:changes` | Show uncommitted changes |
| `task clean:all` | Clean all generated files |

**Examples:**
```bash
# Check all versions
task version

# View git status
task git:status

# Clean everything
task clean:all
```

## Common Workflows

### First-Time Setup

```bash
# 1. Install dependencies
task setup

# 2. Start documentation server
task docs:serve

# 3. In another terminal, configure Traefik
task traefik:configure
```

### Daily Development

```bash
# Start docs server
task docs:serve

# Check status
task monitor:status

# View logs
task docker:logs:dokploy -- --tail 50
task traefik:logs:follow
```

### Before Deployment

```bash
# Run all tests
task test:all

# Build documentation
task docs:build:strict

# Create backups
task db:backup
task traefik:backup

# Check system health
task monitor:health
```

### Troubleshooting

```bash
# Check versions
task version

# View all logs
task docker:logs:dokploy
task docker:logs:postgres
task traefik:logs:acme

# Check configuration
task traefik:config:show

# Restart services
task traefik:restart
```

## Advanced Usage

### Passing Arguments

Use `--` to pass arguments to the underlying command:

```bash
# Pass arguments to docker logs
task docker:logs:dokploy -- --tail 100 --follow

# Pass arguments to traefik logs
task traefik:logs -- --since 1h
```

### Environment Variables

Override variables:

```bash
# Use custom container name
CONTAINER_NAME=my-traefik task traefik:status

# Use custom docs directory
DOCS_DIR=documentation task docs:build
```

### Chaining Tasks

Run multiple tasks in sequence:

```bash
# Clean, build, and deploy docs
task docs:clean docs:build docs:deploy

# Backup everything
task db:backup traefik:backup
```

## Task File Structure

The `Taskfile.yml` is organized into sections:

```yaml
vars:              # Global variables
  DOCS_DIR: docs
  SCRIPTS_DIR: scripts
  ...

tasks:
  # Documentation tasks
  docs:serve: ...
  docs:build: ...
  
  # Traefik tasks
  traefik:configure: ...
  traefik:logs: ...
  
  # Docker tasks
  docker:services: ...
  docker:logs:dokploy: ...
  
  # Database tasks
  db:backup: ...
  db:restore: ...
  
  # And more...
```

## Customization

### Add Custom Tasks

Edit `Taskfile.yml` to add your own tasks:

```yaml
tasks:
  my-task:
    desc: My custom task
    cmds:
      - echo "Running my task"
      - ./my-script.sh
```

### Override Variables

Create a `Taskfile.local.yml` (gitignored) for local overrides:

```yaml
version: '3'

vars:
  CONTAINER_NAME: my-custom-name
  TRAEFIK_DIR: /custom/path
```

Then use it:

```bash
task --taskfile Taskfile.local.yml my-task
```

## Troubleshooting

### Task Not Found

**Error**: `task: Task "xxx" not found`

**Solution**: Check task name with `task --list`

### Permission Denied

**Error**: `Permission denied` when running Traefik tasks

**Solution**: Traefik tasks require sudo. The Taskfile includes `sudo` where needed.

### Command Not Found

**Error**: `command not found: mkdocs`

**Solution**: Install dependencies:
```bash
task dev:install
```

### Docker Errors

**Error**: `Cannot connect to Docker daemon`

**Solution**: 
```bash
# Check Docker is running
docker ps

# Start Docker service
sudo systemctl start docker
```

## Task vs. Make

Task is a modern alternative to Make with several advantages:

| Feature | Task | Make |
|---------|------|------|
| **Syntax** | YAML (readable) | Makefile (complex) |
| **Cross-platform** | Yes | Limited |
| **Variables** | Built-in | Limited |
| **Dependencies** | Easy | Complex |
| **Prompts** | Built-in | Manual |
| **Error handling** | Better | Basic |

## Resources

- **Task Documentation**: https://taskfile.dev/
- **Task GitHub**: https://github.com/go-task/task
- **Installation Guide**: https://taskfile.dev/installation/
- **Usage Guide**: https://taskfile.dev/usage/

## Best Practices

1. **Use descriptive names**: `docs:serve` not `ds`
2. **Group related tasks**: Use `:` for namespacing
3. **Add descriptions**: All tasks should have `desc:`
4. **Use prompts**: For destructive operations
5. **Test commands**: Before adding to Taskfile
6. **Document dependencies**: In task description
7. **Keep it simple**: One task = one purpose

## Getting Help

```bash
# List all tasks
task --list

# Show detailed help
task help

# View task details
task --summary <task-name>

# Dry run (show what would be executed)
task --dry <task-name>
```

---

**Taskfile Version**: 3  
**Created**: 2025-01-02  
**Total Tasks**: 50+  
**Status**: Production Ready
