# Dokploy Installation Script Documentation

## Overview

The Dokploy installation script is a bash-based automated installer that deploys Dokploy on Linux systems using Docker Swarm. It handles installation, configuration, and updates of the Dokploy platform along with its dependencies (PostgreSQL, Redis, and Traefik).

**Script URL**: `https://dokploy.com/install.sh`

## System Requirements

### Supported Platforms
- **Operating System**: Linux only (not macOS or Windows)
- **Execution Context**: Must run directly on host (not inside a container)
- **Privileges**: Must run as root user
- **Docker**: Automatically installs Docker 28.5.0 if not present

### Port Requirements
The following ports must be available before installation:
- **Port 80**: HTTP traffic (Traefik)
- **Port 443**: HTTPS traffic (Traefik)
- **Port 3000**: Dokploy web interface

### Special Environments
- **Proxmox LXC**: Supported with automatic detection and DNS round-robin endpoint mode configuration

## Usage Methods

### Basic Installation (Latest Version)

```bash
curl -sSL https://dokploy.com/install.sh | sh
```

### Version-Specific Installation

#### Method 1: Export Environment Variable
```bash
export DOKPLOY_VERSION=canary
curl -sSL https://dokploy.com/install.sh | sh
```

#### Method 2: Inline with Curl
```bash
DOKPLOY_VERSION=canary bash -s < <(curl -sSL https://dokploy.com/install.sh)
```

#### Method 3: Download and Execute
```bash
curl -sSL https://dokploy.com/install.sh -o install.sh
DOKPLOY_VERSION=feature bash install.sh
```

### Available Versions
- `latest` (default)
- `canary`
- `feature`

### Updating Dokploy

```bash
curl -sSL https://dokploy.com/install.sh | sh -s update
```

Or with specific version:
```bash
export DOKPLOY_VERSION=canary
curl -sSL https://dokploy.com/install.sh | sh -s update
```

## Environment Variables

### Version Control

| Variable | Description | Default | Example |
|----------|-------------|---------|---------|
| `DOKPLOY_VERSION` | Specifies the version to install | `latest` | `canary`, `feature` |

### Network Configuration

| Variable | Description | Default | Example |
|----------|-------------|---------|---------|
| `ADVERTISE_ADDR` | Docker Swarm advertise address | Auto-detected private IP | `192.168.1.100` |
| `DOCKER_SWARM_INIT_ARGS` | Custom Docker Swarm initialization arguments | None | `--default-addr-pool 172.20.0.0/16` |

#### ADVERTISE_ADDR Auto-Detection Priority
1. User-provided `ADVERTISE_ADDR` environment variable
2. Auto-detected private IP (RFC 1918 ranges: 192.168.x.x, 10.x.x.x, 172.16-31.x.x)

#### DOCKER_SWARM_INIT_ARGS Use Cases
- Avoid CIDR conflicts with cloud provider VPCs (AWS, Azure, GCP)
- Custom subnet configurations
- Advanced Docker Swarm networking requirements

**Example for AWS environments:**
```bash
export DOCKER_SWARM_INIT_ARGS="--default-addr-pool 172.20.0.0/16 --default-addr-pool-mask-length 24"
curl -sSL https://dokploy.com/install.sh | sh
```

## Installation Process

### Pre-Installation Checks

1. **Root Privilege Verification**: Ensures script runs as root
2. **Platform Validation**: Confirms Linux environment
3. **Container Detection**: Prevents installation inside Docker containers
4. **Port Availability**: Validates ports 80, 443, and 3000 are free
5. **Docker Installation**: Installs Docker 28.5.0 if missing
6. **LXC Detection**: Identifies Proxmox LXC environment

### Core Installation Steps

#### 1. Docker Swarm Initialization
- Leaves existing swarm (if any)
- Initializes new swarm with advertise address
- Supports custom initialization arguments

#### 2. Network Creation
- Creates overlay network: `dokploy-network`
- Driver: overlay
- Attachable: yes

#### 3. Directory Setup
- Creates `/etc/dokploy` directory
- Sets permissions: 777

#### 4. PostgreSQL Service Deployment
```bash
Service Name: dokploy-postgres
Image: postgres:16
Network: dokploy-network
Constraints: Manager node only
Environment:
  - POSTGRES_USER=dokploy
  - POSTGRES_DB=dokploy
  - POSTGRES_PASSWORD=amukds4wi9001583845717ad2
Volume: dokploy-postgres → /var/lib/postgresql/data
```

#### 5. Redis Service Deployment
```bash
Service Name: dokploy-redis
Image: redis:7
Network: dokploy-network
Constraints: Manager node only
Volume: dokploy-redis → /data
```

#### 6. Dokploy Service Deployment
```bash
Service Name: dokploy
Image: dokploy/dokploy:{VERSION_TAG}
Network: dokploy-network
Constraints: Manager node only
Replicas: 1
Ports: 3000 (host mode)
Update Strategy:
  - Parallelism: 1
  - Order: stop-first
Mounts:
  - /var/run/docker.sock:/var/run/docker.sock
  - /etc/dokploy:/etc/dokploy
  - dokploy:/root/.docker (volume)
Environment:
  - ADVERTISE_ADDR={detected_or_provided}
  - RELEASE_TAG={version} (if not latest)
```

#### 7. Traefik Reverse Proxy Deployment
```bash
Container Name: dokploy-traefik
Image: traefik:v3.6.1
Deployment: Docker container (not swarm service)
Restart Policy: always
Networks: dokploy-network
Ports:
  - 80:80/tcp
  - 443:443/tcp
  - 443:443/udp
Mounts:
  - /etc/dokploy/traefik/traefik.yml:/etc/traefik/traefik.yml
  - /etc/dokploy/traefik/dynamic:/etc/dokploy/traefik/dynamic
  - /var/run/docker.sock:/var/run/docker.sock:ro
```

## Components and Architecture

### Docker Volumes
- `dokploy-postgres`: PostgreSQL data persistence
- `dokploy-redis`: Redis data persistence
- `dokploy`: Docker credentials and configuration

### Docker Network
- **Name**: dokploy-network
- **Type**: Overlay (multi-host capable)
- **Attachable**: Yes (allows standalone containers to attach)

### Services Overview

| Service | Type | Image | Purpose |
|---------|------|-------|---------|
| dokploy-postgres | Swarm Service | postgres:16 | Database backend |
| dokploy-redis | Swarm Service | redis:7 | Cache and queue |
| dokploy | Swarm Service | dokploy/dokploy | Main application |
| dokploy-traefik | Container | traefik:v3.6.1 | Reverse proxy |

## Special Considerations

### Proxmox LXC Containers

When running inside a Proxmox LXC container, the script automatically:
1. Detects the LXC environment via:
   - `$container` environment variable
   - `/proc/1/environ` inspection
2. Applies `--endpoint-mode dnsrr` to all services
3. Displays warning about DNS round-robin mode
4. Waits 5 seconds before proceeding

**Impact**: DNS round-robin mode affects service discovery but is required for LXC compatibility.

### IP Address Detection

#### Private IP Detection
Searches for RFC 1918 private addresses in this order:
1. 192.168.x.x
2. 10.x.x.x
3. 172.16-31.x.x

#### Public IP Detection (Fallback)
Attempts IPv4 detection via:
1. https://ifconfig.io
2. https://icanhazip.com
3. https://ipecho.net/plain

Attempts IPv6 detection (if IPv4 fails) via:
1. https://ifconfig.io
2. https://icanhazip.com
3. https://ipecho.net/plain

**Timeout**: 5 seconds per attempt

### IPv6 Support
The script automatically formats IPv6 addresses in URLs:
- IPv4: `http://192.168.1.100:3000`
- IPv6: `http://[2001:db8::1]:3000`

## Update Process

The update function performs:
1. Version detection
2. Docker image pull: `dokploy/dokploy:{VERSION_TAG}`
3. Service update with new image
4. Zero-downtime deployment (due to stop-first strategy)

**Command:**
```bash
curl -sSL https://dokploy.com/install.sh | sh -s update
```

## Post-Installation

### Access Information
After successful installation:
- **Wait Time**: 15 seconds for services to start
- **URL**: `http://{PUBLIC_IP}:3000`
- **Format**: Auto-formatted for IPv4/IPv6

### Default Credentials
The PostgreSQL credentials are:
- **User**: dokploy
- **Database**: dokploy
- **Password**: amukds4wi9001583845717ad2

**⚠️ Security Note**: Change default PostgreSQL password in production environments.

## Troubleshooting

### Common Issues

#### Port Already in Use
**Error**: "something is already running on port X"
**Solution**: Stop services using ports 80, 443, or 3000

```bash
# Identify process using port
sudo ss -tulnp | grep ':80 '
# Stop the service
sudo systemctl stop <service_name>
```

#### Cannot Detect IP Address
**Error**: "Could not determine server IP address automatically"
**Solution**: Manually set ADVERTISE_ADDR

```bash
export ADVERTISE_ADDR=192.168.1.100
curl -sSL https://dokploy.com/install.sh | sh
```

#### Docker Swarm Initialization Failed
**Error**: "Failed to initialize Docker Swarm"
**Solution**: Check network connectivity and existing swarm state

```bash
# Check current swarm status
docker info | grep Swarm
# Force leave if necessary
docker swarm leave --force
```

#### Running on macOS
**Error**: "This script must be run on Linux"
**Solution**: Use a Linux VM or VPS. Dokploy requires Linux kernel features.

### Service Management

#### Check Service Status
```bash
docker service ls
docker service ps dokploy
docker service logs dokploy
```

#### Restart Services
```bash
docker service update --force dokploy
docker restart dokploy-traefik
```

#### Remove Installation
```bash
# Stop and remove services
docker service rm dokploy dokploy-postgres dokploy-redis
docker stop dokploy-traefik && docker rm dokploy-traefik

# Remove network
docker network rm dokploy-network

# Remove volumes (optional - deletes data)
docker volume rm dokploy dokploy-postgres dokploy-redis

# Leave swarm
docker swarm leave --force

# Remove configuration
sudo rm -rf /etc/dokploy
```

## Security Considerations

### Exposed Credentials
The script contains hardcoded PostgreSQL credentials. For production:
1. Change database password after installation
2. Update Dokploy configuration to use new credentials
3. Restrict access to `/etc/dokploy` directory

### Network Security
- Default setup exposes port 3000 publicly
- Consider using firewall rules to restrict access
- Use Traefik SSL/TLS configuration for HTTPS

### Docker Socket Access
Multiple services mount `/var/run/docker.sock`:
- This grants full Docker API access
- Required for Dokploy functionality
- Ensure host system security is maintained

## Advanced Configuration

### Custom Swarm Network Pools
To avoid IP conflicts with cloud infrastructure:

```bash
export DOCKER_SWARM_INIT_ARGS="--default-addr-pool 172.20.0.0/16 --default-addr-pool-mask-length 24"
curl -sSL https://dokploy.com/install.sh | sh
```

### Using Traefik as Swarm Service
The script includes commented code for deploying Traefik as a swarm service instead of a standalone container. This approach provides:
- Better high availability
- Automatic restart on manager nodes
- Swarm-native management

**Note**: Currently disabled by default; uncomment relevant section in script to enable.

## Script Functions Reference

### `detect_version()`
**Purpose**: Detects installation version from environment  
**Returns**: Version tag (latest, canary, or feature)  
**Environment**: Reads `$DOKPLOY_VERSION`

### `is_proxmox_lxc()`
**Purpose**: Detects Proxmox LXC container environment  
**Returns**: 0 if LXC, 1 otherwise  
**Detection Methods**: Environment variable, /proc/1/environ inspection

### `get_ip()`
**Purpose**: Retrieves public IP address (IPv4 or IPv6)  
**Returns**: IP address string or exits on failure  
**Timeout**: 5 seconds per attempt

### `get_private_ip()`
**Purpose**: Retrieves private RFC 1918 IP address  
**Returns**: Private IP or empty string  
**Method**: Parses `ip addr show` output

### `format_ip_for_url()`
**Purpose**: Formats IP for URL display  
**Returns**: Bracketed IPv6 or plain IPv4  
**Usage**: URL formatting in success message

### `command_exists()`
**Purpose**: Checks if command is available  
**Returns**: 0 if exists, 1 otherwise  
**Usage**: Docker installation check

### `install_dokploy()`
**Purpose**: Main installation routine  
**Actions**: All installation steps  
**Exit Codes**: 1 on any failure

### `update_dokploy()`
**Purpose**: Updates existing Dokploy installation  
**Actions**: Pull and update Docker service  
**Requirements**: Existing Dokploy installation

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Failure (permissions, platform, ports, network, etc.) |

## Version Information

### Component Versions (as of documentation)
- **Docker**: 28.5.0 (auto-installed)
- **PostgreSQL**: 16
- **Redis**: 7
- **Traefik**: v3.6.1
- **Dokploy**: Variable (latest/canary/feature)

## References

- **Official Script**: https://dokploy.com/install.sh
- **Docker Swarm Documentation**: https://docs.docker.com/engine/swarm/
- **Traefik Documentation**: https://doc.traefik.io/traefik/
