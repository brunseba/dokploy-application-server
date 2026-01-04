#!/usr/bin/env bash
set -euo pipefail

# traefik-start.sh - Start Traefik container with configuration from inspect
#
# This script recreates the Traefik container based on the configuration
# extracted from inputs/dokploy-traefik.inspect
#
# Usage:
#   ./scripts/traefik-start.sh [OPTIONS]
#
# Options:
#   --force         Stop and remove existing container before starting
#   --dry-run       Show the docker command without executing
#   -h, --help      Show this help message
#
# Configuration:
#   Image: traefik:v3.6.1
#   Ports: 80, 443/tcp, 443/udp
#   Restart: always
#   Network: dokploy-network
#   Volumes:
#     - /etc/dokploy/traefik/traefik.yml:/etc/traefik/traefik.yml
#     - /etc/dokploy/traefik/dynamic:/etc/dokploy/traefik/dynamic
#     - /var/run/docker.sock:/var/run/docker.sock:ro

# Configuration
CONTAINER_NAME="dokploy-traefik"
IMAGE="traefik:v3.6.1"
NETWORK="dokploy-network"
CONFIG_DIR="/etc/dokploy/traefik"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1" >&2
}

show_help() {
    sed -n '/^# Usage:/,/^$/p' "$0" | sed 's/^# \?//'
    exit 0
}

check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if docker is available
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed or not in PATH"
        exit 1
    fi
    
    # Check if docker is running
    if ! docker info &> /dev/null; then
        log_error "Docker daemon is not running"
        exit 1
    fi
    
    # Check if network exists
    if ! docker network inspect "$NETWORK" &> /dev/null; then
        log_warning "Network '$NETWORK' does not exist"
        log_info "Creating network '$NETWORK'..."
        docker network create "$NETWORK"
        log_success "Network created"
    fi
    
    # Check if config files exist
    if [ ! -f "$CONFIG_DIR/traefik.yml" ]; then
        log_error "Configuration file not found: $CONFIG_DIR/traefik.yml"
        exit 1
    fi
    
    if [ ! -d "$CONFIG_DIR/dynamic" ]; then
        log_warning "Dynamic config directory not found: $CONFIG_DIR/dynamic"
        log_info "Creating directory..."
        sudo mkdir -p "$CONFIG_DIR/dynamic"
        log_success "Directory created"
    fi
    
    log_success "Prerequisites check passed"
}

check_existing_container() {
    if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        return 0
    else
        return 1
    fi
}

stop_and_remove_container() {
    log_info "Stopping existing container '$CONTAINER_NAME'..."
    if docker stop "$CONTAINER_NAME" &> /dev/null; then
        log_success "Container stopped"
    else
        log_warning "Failed to stop container (may not be running)"
    fi
    
    log_info "Removing existing container '$CONTAINER_NAME'..."
    if docker rm "$CONTAINER_NAME" &> /dev/null; then
        log_success "Container removed"
    else
        log_error "Failed to remove container"
        exit 1
    fi
}

start_container() {
    log_info "Starting Traefik container..."
    
    docker run -d \
        --name "$CONTAINER_NAME" \
        --restart always \
        -p 80:80 \
        -p 443:443/tcp \
        -p 443:443/udp \
        -v "$CONFIG_DIR/traefik.yml:/etc/traefik/traefik.yml" \
        -v "$CONFIG_DIR/dynamic:/etc/dokploy/traefik/dynamic" \
        -v /var/run/docker.sock:/var/run/docker.sock:ro \
        --network "$NETWORK" \
        "$IMAGE"
    
    log_success "Container started: $CONTAINER_NAME"
}

show_container_info() {
    echo ""
    log_info "Container information:"
    echo ""
    docker ps --filter "name=^${CONTAINER_NAME}$" --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}"
    echo ""
    log_info "View logs with: docker logs -f $CONTAINER_NAME"
    log_info "Check status with: docker ps -f name=$CONTAINER_NAME"
}

# Parse arguments
FORCE=false
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --force)
            FORCE=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            show_help
            ;;
        *)
            log_error "Unknown option: $1"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

# Dry run mode
if [ "$DRY_RUN" = true ]; then
    echo "docker run -d \\"
    echo "  --name $CONTAINER_NAME \\"
    echo "  --restart always \\"
    echo "  -p 80:80 \\"
    echo "  -p 443:443/tcp \\"
    echo "  -p 443:443/udp \\"
    echo "  -v $CONFIG_DIR/traefik.yml:/etc/traefik/traefik.yml \\"
    echo "  -v $CONFIG_DIR/dynamic:/etc/dokploy/traefik/dynamic \\"
    echo "  -v /var/run/docker.sock:/var/run/docker.sock:ro \\"
    echo "  --network $NETWORK \\"
    echo "  $IMAGE"
    exit 0
fi

# Main execution
echo ""
log_info "Traefik Container Starter"
echo ""

check_prerequisites

if check_existing_container; then
    if [ "$FORCE" = true ]; then
        stop_and_remove_container
    else
        log_error "Container '$CONTAINER_NAME' already exists"
        log_info "Use --force to stop and remove the existing container"
        exit 1
    fi
fi

start_container
show_container_info

log_success "Done!"
