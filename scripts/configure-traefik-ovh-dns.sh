#!/usr/bin/env bash
#
# configure-traefik-ovh-dns.sh
# 
# This script updates Traefik configuration to use OVH DNS challenge with Let's Encrypt
# for automatic SSL certificate generation and renewal.
#
# Prerequisites:
# - Traefik container named 'dokploy-traefik'
# - OVH API credentials (Application Key, Application Secret, Consumer Key)
# - Access to /etc/dokploy/traefik/ directory
#
# Usage:
#   ./configure-traefik-ovh-dns.sh \
#     --email YOUR_EMAIL \
#     --endpoint ovh-eu \
#     --app-key YOUR_APP_KEY \
#     --app-secret YOUR_APP_SECRET \
#     --consumer-key YOUR_CONSUMER_KEY
#

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
TRAEFIK_DIR="/etc/dokploy/traefik"
TRAEFIK_CONFIG="${TRAEFIK_DIR}/traefik.yml"
TRAEFIK_DYNAMIC_DIR="${TRAEFIK_DIR}/dynamic"
ACME_JSON="${TRAEFIK_DYNAMIC_DIR}/acme.json"
CONTAINER_NAME="dokploy-traefik"
NETWORK="dokploy-network"
OVH_ENDPOINT="ovh-eu"
EMAIL=""
OVH_APP_KEY=""
OVH_APP_SECRET=""
OVH_CONSUMER_KEY=""
BACKUP_SUFFIX=$(date +%Y%m%d_%H%M%S)

# Function to print colored output
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to print usage
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Configure Traefik to use OVH DNS challenge for Let's Encrypt certificates

Required Options:
    --email EMAIL               Email address for Let's Encrypt
    --app-key KEY               OVH Application Key
    --app-secret SECRET         OVH Application Secret
    --consumer-key KEY          OVH Consumer Key

Optional Options:
    --endpoint ENDPOINT         OVH API endpoint (default: ovh-eu)
                               Options: ovh-eu, ovh-ca, ovh-us
    --traefik-dir PATH         Traefik configuration directory (default: /etc/dokploy/traefik)
    --container-name NAME      Traefik container name (default: dokploy-traefik)
    --dry-run                  Show what would be done without making changes
    -h, --help                 Show this help message

Examples:
    # Configure with OVH EU endpoint
    $0 --email admin@example.com \\
       --app-key abc123 \\
       --app-secret def456 \\
       --consumer-key ghi789

    # Dry run to see changes
    $0 --email admin@example.com \\
       --app-key abc123 \\
       --app-secret def456 \\
       --consumer-key ghi789 \\
       --dry-run

OVH API Credentials:
    Get your credentials from: https://api.ovh.com/createToken/
    Required rights for DNS:
    - GET /domain/zone/*
    - POST /domain/zone/*
    - DELETE /domain/zone/*

EOF
    exit 1
}

# Parse command line arguments
DRY_RUN=false
while [[ $# -gt 0 ]]; do
    case $1 in
        --email)
            EMAIL="$2"
            shift 2
            ;;
        --app-key)
            OVH_APP_KEY="$2"
            shift 2
            ;;
        --app-secret)
            OVH_APP_SECRET="$2"
            shift 2
            ;;
        --consumer-key)
            OVH_CONSUMER_KEY="$2"
            shift 2
            ;;
        --endpoint)
            OVH_ENDPOINT="$2"
            shift 2
            ;;
        --traefik-dir)
            TRAEFIK_DIR="$2"
            TRAEFIK_CONFIG="${TRAEFIK_DIR}/traefik.yml"
            TRAEFIK_DYNAMIC_DIR="${TRAEFIK_DIR}/dynamic"
            ACME_JSON="${TRAEFIK_DYNAMIC_DIR}/acme.json"
            shift 2
            ;;
        --container-name)
            CONTAINER_NAME="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            log_error "Unknown option: $1"
            usage
            ;;
    esac
done

# Validate required parameters
if [[ -z "$EMAIL" ]]; then
    log_error "Email is required"
    usage
fi

if [[ -z "$OVH_APP_KEY" ]]; then
    log_error "OVH Application Key is required"
    usage
fi

if [[ -z "$OVH_APP_SECRET" ]]; then
    log_error "OVH Application Secret is required"
    usage
fi

if [[ -z "$OVH_CONSUMER_KEY" ]]; then
    log_error "OVH Consumer Key is required"
    usage
fi

# Validate OVH endpoint
case $OVH_ENDPOINT in
    ovh-eu|ovh-ca|ovh-us)
        ;;
    *)
        log_error "Invalid OVH endpoint: $OVH_ENDPOINT"
        log_error "Valid options: ovh-eu, ovh-ca, ovh-us"
        exit 1
        ;;
esac

log_info "Starting Traefik OVH DNS configuration..."
log_info "Email: $EMAIL"
log_info "OVH Endpoint: $OVH_ENDPOINT"
log_info "Traefik Directory: $TRAEFIK_DIR"
log_info "Container Name: $CONTAINER_NAME"

if [ "$DRY_RUN" = true ]; then
    log_warn "DRY RUN MODE - No changes will be made"
fi

# Check if running as root (needed for /etc access)
if [ "$EUID" -ne 0 ] && [ ! -w "$TRAEFIK_DIR" ]; then 
    log_error "This script needs write access to $TRAEFIK_DIR"
    log_error "Please run with sudo or as root"
    exit 1
fi

log_info "Checking prerequisites..."

# Check if docker is available
if ! command -v docker &> /dev/null; then
    log_error "Docker is not installed or not in PATH"
    exit 1
fi

# Check if Docker is running
if ! docker info &> /dev/null; then
    log_error "Docker daemon is not running"
    exit 1
fi

# Check if network exists
if ! docker network inspect "$NETWORK" &> /dev/null; then
    log_warn "Network 'dokploy-network' does not exist"
    log_info "Creating network 'dokploy-network'..."
    docker network create dokploy-network
    log_info "Network created"
fi

# Check if Traefik directory exists
if [ ! -d "$TRAEFIK_DIR" ]; then
    log_error "Traefik directory not found: $TRAEFIK_DIR"
    log_info "Creating directory..."
    sudo mkdir -p "$TRAEFIK_DIR/dynamic"
    log_info "Directory created"
fi

# Check if Traefik config exists
if [ ! -f "$TRAEFIK_CONFIG" ]; then
    log_error "Traefik configuration file not found: $TRAEFIK_CONFIG"
    exit 1
fi

# Check if Traefik container exists (not required, will be created)
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    log_info "Existing Traefik container found: $CONTAINER_NAME"
else
    log_info "No existing Traefik container found (will be created)"
fi

log_info "Prerequisites check passed"

# Backup existing configuration
if [ "$DRY_RUN" = false ]; then
    log_info "Creating backup of existing configuration..."
    cp "$TRAEFIK_CONFIG" "${TRAEFIK_CONFIG}.backup.${BACKUP_SUFFIX}"
    log_info "Backup created: ${TRAEFIK_CONFIG}.backup.${BACKUP_SUFFIX}"
    
    if [ -f "$ACME_JSON" ]; then
        cp "$ACME_JSON" "${ACME_JSON}.backup.${BACKUP_SUFFIX}"
        log_info "Backup created: ${ACME_JSON}.backup.${BACKUP_SUFFIX}"
    fi
fi

# Create new Traefik configuration with OVH DNS challenge
log_info "Generating new Traefik configuration..."

NEW_CONFIG=$(cat << EOF
global:
  sendAnonymousUsage: false
providers:
  swarm:
    exposedByDefault: false
    watch: true
  docker:
    exposedByDefault: false
    watch: true
    network: dokploy-network
  file:
    directory: /etc/dokploy/traefik/dynamic
    watch: true
entryPoints:
  web:
    address: :80
  websecure:
    address: :443
    http3:
      advertisedPort: 443
    http:
      tls:
        certResolver: letsencrypt
api:
  insecure: true
certificatesResolvers:
  letsencrypt:
    acme:
      email: ${EMAIL}
      storage: /etc/dokploy/traefik/dynamic/acme.json
      dnsChallenge:
        provider: ovh
        delayBeforeCheck: 10
        resolvers:
          - 1.1.1.1:53
          - 8.8.8.8:53
EOF
)

if [ "$DRY_RUN" = true ]; then
    log_info "Would write the following configuration to $TRAEFIK_CONFIG:"
    echo "---"
    echo "$NEW_CONFIG"
    echo "---"
else
    echo "$NEW_CONFIG" > "$TRAEFIK_CONFIG"
    log_info "Configuration written to $TRAEFIK_CONFIG"
fi

# Reset ACME storage
if [ "$DRY_RUN" = false ]; then
    log_info "Resetting ACME storage..."
    echo "{}" > "$ACME_JSON"
    chmod 600 "$ACME_JSON"
    log_info "ACME storage reset: $ACME_JSON"
fi

# Stop and remove existing container if it exists
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    log_info "Stopping existing container '$CONTAINER_NAME'..."
    if [ "$DRY_RUN" = false ]; then
        docker stop "$CONTAINER_NAME" &> /dev/null || log_warn "Container may already be stopped"
        log_info "Removing existing container '$CONTAINER_NAME'..."
        docker rm -f "$CONTAINER_NAME" &> /dev/null || true
    else
        log_info "Would stop and remove container: $CONTAINER_NAME"
    fi
else
    log_info "No existing container to remove"
fi

# Prepare docker run command with OVH environment variables
log_info "Preparing to restart Traefik with OVH credentials..."

DOCKER_RUN_CMD="docker run -d \\
  --name ${CONTAINER_NAME} \\
  --restart always \\
  -p 80:80 \\
  -p 443:443/tcp \\
  -p 443:443/udp \\
  -v ${TRAEFIK_DIR}/traefik.yml:/etc/traefik/traefik.yml \\
  -v ${TRAEFIK_DYNAMIC_DIR}:/etc/dokploy/traefik/dynamic \\
  -v /var/run/docker.sock:/var/run/docker.sock:ro \\
  --network ${NETWORK} \\
  -e OVH_ENDPOINT=${OVH_ENDPOINT} \\
  -e OVH_APPLICATION_KEY=${OVH_APP_KEY} \\
  -e OVH_APPLICATION_SECRET=${OVH_APP_SECRET} \\
  -e OVH_CONSUMER_KEY=${OVH_CONSUMER_KEY} \\
  traefik:v3.6.1"

if [ "$DRY_RUN" = true ]; then
    log_info "Would remove existing container and run:"
    echo "---"
    echo "$DOCKER_RUN_CMD"
    echo "---"
else
    # Remove old container
    docker rm -f "$CONTAINER_NAME" 2>/dev/null || true
    
    # Run new container with OVH credentials
    log_info "Starting Traefik with OVH DNS challenge..."
    eval "$DOCKER_RUN_CMD"
    
    # Wait for container to start
    sleep 3
    
    # Check if container is running
    if docker ps | grep -q "$CONTAINER_NAME"; then
        log_info "✓ Traefik container started successfully"
        
        # Show container status
        log_info "Container status:"
        docker ps --filter "name=${CONTAINER_NAME}" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
        
        # Show logs
        log_info "Recent logs:"
        docker logs --tail 20 "$CONTAINER_NAME"
    else
        log_error "Failed to start Traefik container"
        log_error "Check logs with: docker logs $CONTAINER_NAME"
        exit 1
    fi
fi

# Summary
echo ""
log_info "=== Configuration Summary ==="
log_info "Traefik has been configured to use OVH DNS challenge"
log_info "Email: $EMAIL"
log_info "OVH Endpoint: $OVH_ENDPOINT"
log_info "Challenge Type: DNS (OVH)"
log_info "ACME Storage: $ACME_JSON"

if [ "$DRY_RUN" = false ]; then
    echo ""
    log_info "=== Next Steps ==="
    log_info "1. Verify Traefik is running: docker ps | grep traefik"
    log_info "2. Check logs: docker logs -f $CONTAINER_NAME"
    log_info "3. Monitor certificate generation in: $ACME_JSON"
    log_info "4. Test your domain SSL: https://your-domain.com"
    echo ""
    log_info "Backups created:"
    log_info "  - ${TRAEFIK_CONFIG}.backup.${BACKUP_SUFFIX}"
    if [ -f "${ACME_JSON}.backup.${BACKUP_SUFFIX}" ]; then
        log_info "  - ${ACME_JSON}.backup.${BACKUP_SUFFIX}"
    fi
    echo ""
    log_info "To rollback, run:"
    log_info "  sudo cp ${TRAEFIK_CONFIG}.backup.${BACKUP_SUFFIX} ${TRAEFIK_CONFIG}"
    log_info "  sudo docker restart ${CONTAINER_NAME}"
else
    echo ""
    log_warn "DRY RUN completed - no changes were made"
    log_info "Run without --dry-run to apply changes"
fi

echo ""
log_info "Done! ✓"
