# Script Reference

Complete reference for the Traefik OVH DNS configuration script.

## Script: configure-traefik-ovh-dns.sh

Located at: `scripts/configure-traefik-ovh-dns.sh`

### Purpose

Automates the configuration of Traefik to use OVH DNS challenge for Let's Encrypt SSL certificates.

### Usage

```bash
sudo ./scripts/configure-traefik-ovh-dns.sh [OPTIONS]
```

### Required Options

| Option | Description | Example |
|--------|-------------|---------|
| `--email` | Email for Let's Encrypt notifications | `admin@example.com` |
| `--app-key` | OVH Application Key | `abc123...` |
| `--app-secret` | OVH Application Secret | `def456...` |
| `--consumer-key` | OVH Consumer Key | `ghi789...` |

### Optional Options

| Option | Default | Description |
|--------|---------|-------------|
| `--endpoint` | `ovh-eu` | OVH API endpoint (ovh-eu, ovh-ca, ovh-us) |
| `--traefik-dir` | `/etc/dokploy/traefik` | Traefik configuration directory |
| `--container-name` | `dokploy-traefik` | Traefik container name |
| `--dry-run` | false | Test mode - show changes without applying |
| `-h, --help` | - | Show help message |

### Examples

**Basic usage:**
```bash
sudo ./scripts/configure-traefik-ovh-dns.sh \
  --email admin@example.com \
  --app-key YOUR_APP_KEY \
  --app-secret YOUR_APP_SECRET \
  --consumer-key YOUR_CONSUMER_KEY
```

**With custom endpoint:**
```bash
sudo ./scripts/configure-traefik-ovh-dns.sh \
  --endpoint ovh-ca \
  --email admin@example.com \
  --app-key YOUR_APP_KEY \
  --app-secret YOUR_APP_SECRET \
  --consumer-key YOUR_CONSUMER_KEY
```

**Dry-run mode (recommended first):**
```bash
sudo ./scripts/configure-traefik-ovh-dns.sh \
  --email admin@example.com \
  --app-key YOUR_APP_KEY \
  --app-secret YOUR_APP_SECRET \
  --consumer-key YOUR_CONSUMER_KEY \
  --dry-run
```

### What the Script Does

1. **Validates inputs** - Checks all required parameters
2. **Creates backups** - Backs up configuration with timestamps
3. **Updates traefik.yml** - Changes HTTP challenge to DNS challenge
4. **Configures DNS resolvers** - Sets Cloudflare and Google DNS
5. **Resets ACME storage** - Clears old certificates
6. **Recreates container** - Adds OVH environment variables
7. **Verifies startup** - Checks container is running

### Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Missing required parameter |
| 2 | Invalid parameter value |
| 3 | File/directory not found |
| 4 | Docker command failed |
| 5 | Container not running after restart |

### Environment Variables Set

The script configures these environment variables in the Traefik container:

- `OVH_ENDPOINT` - API endpoint region
- `OVH_APPLICATION_KEY` - OVH application key
- `OVH_APPLICATION_SECRET` - OVH application secret
- `OVH_CONSUMER_KEY` - OVH consumer key

### Files Modified

- `/etc/dokploy/traefik/traefik.yml` - Main Traefik configuration
- `/etc/dokploy/traefik/dynamic/acme.json` - ACME certificate storage

### Backup Files Created

Format: `{filename}.backup.YYYYMMDD_HHMMSS`

Example:
- `traefik.yml.backup.20241231_103045`
- `acme.json.backup.20241231_103045`

## Related Documentation

- [Traefik OVH DNS Setup Guide](../traefik-ovh-dns-setup.md) - Complete setup guide
- [Troubleshooting](troubleshooting.md) - Common issues and solutions

---

**Script Version**: 1.0  
**Last Updated**: 2024-12-31
