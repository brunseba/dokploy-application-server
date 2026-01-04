# Traefik OVH DNS Configuration Guide

This guide explains how to configure Traefik to use OVH DNS challenge with Let's Encrypt for automatic SSL certificate generation.

## Why DNS Challenge?

The DNS challenge is preferred over HTTP challenge when:
- Your domains use OVH DNS
- You want wildcard certificates (*.example.com)
- Ports 80/443 are not accessible from the internet
- You need certificates before the service is publicly accessible

## Prerequisites

1. **OVH Account** with access to DNS management
2. **OVH API Credentials** (Application Key, Application Secret, Consumer Key)
3. **Dokploy** installed with Traefik running
4. **Root/sudo access** to the server

---

## Step 1: Get OVH API Credentials

### Create OVH API Token

1. Go to: https://api.ovh.com/createToken/

2. Log in with your OVH account

3. Fill in the form:
   - **Application Name**: `Dokploy Traefik`
   - **Application Description**: `SSL certificate management for Dokploy`
   - **Validity**: `Unlimited` (recommended) or set an expiration date

4. Set the required rights for DNS management:
   ```
   GET    /domain/zone/*
   POST   /domain/zone/*
   DELETE /domain/zone/*
   ```

5. Click **Create keys**

6. Save the three credentials:
   - **Application Key** (also called Consumer Key in some contexts)
   - **Application Secret**
   - **Consumer Key**

### API Endpoints

Choose the correct endpoint for your region:
- **Europe**: `ovh-eu` (default)
- **Canada**: `ovh-ca`
- **USA**: `ovh-us`

---

## Step 2: Run the Configuration Script

### Basic Usage

```bash
sudo ./scripts/configure-traefik-ovh-dns.sh \
  --email your-email@example.com \
  --app-key YOUR_APPLICATION_KEY \
  --app-secret YOUR_APPLICATION_SECRET \
  --consumer-key YOUR_CONSUMER_KEY
```

### Dry Run (Recommended First)

Test the script without making changes:

```bash
sudo ./scripts/configure-traefik-ovh-dns.sh \
  --email your-email@example.com \
  --app-key YOUR_APPLICATION_KEY \
  --app-secret YOUR_APPLICATION_SECRET \
  --consumer-key YOUR_CONSUMER_KEY \
  --dry-run
```

### Full Example

```bash
sudo ./scripts/configure-traefik-ovh-dns.sh \
  --email admin@lepervier.org \
  --endpoint ovh-eu \
  --app-key abc123def456ghi789 \
  --app-secret jkl012mno345pqr678 \
  --consumer-key stu901vwx234yz567 \
  --container-name dokploy-traefik
```

### Script Options

| Option | Required | Default | Description |
|--------|----------|---------|-------------|
| `--email` | Yes | - | Email for Let's Encrypt notifications |
| `--app-key` | Yes | - | OVH Application Key |
| `--app-secret` | Yes | - | OVH Application Secret |
| `--consumer-key` | Yes | - | OVH Consumer Key |
| `--endpoint` | No | `ovh-eu` | OVH API endpoint (ovh-eu, ovh-ca, ovh-us) |
| `--traefik-dir` | No | `/etc/dokploy/traefik` | Traefik configuration directory |
| `--container-name` | No | `dokploy-traefik` | Traefik container name |
| `--dry-run` | No | false | Show changes without applying |
| `-h, --help` | No | - | Show help message |

---

## Step 3: Verify Configuration

### Check Traefik Container

```bash
# Check if Traefik is running
docker ps | grep traefik

# View Traefik logs
docker logs -f dokploy-traefik

# Check for certificate generation
docker logs dokploy-traefik | grep -i acme
docker logs dokploy-traefik | grep -i certificate
```

### Monitor Certificate Generation

```bash
# Watch ACME storage file
sudo watch -n 5 'cat /etc/dokploy/traefik/dynamic/acme.json | jq'

# Or check file size (should grow from empty {} to several KB)
sudo ls -lh /etc/dokploy/traefik/dynamic/acme.json
```

### Test SSL Certificate

```bash
# Test your domain
curl -I https://your-domain.com

# Check certificate details
openssl s_client -connect your-domain.com:443 -servername your-domain.com < /dev/null 2>/dev/null | openssl x509 -text -noout | grep -A 2 "Issuer"
```

---

## What the Script Does

1. **Validates inputs**: Checks all required parameters and credentials
2. **Creates backups**: Backs up existing configuration with timestamp
3. **Updates Traefik config**: Changes from HTTP challenge to DNS challenge
4. **Resets ACME storage**: Clears old certificates to force regeneration
5. **Restarts Traefik**: Recreates container with OVH environment variables
6. **Verifies startup**: Checks container is running and shows logs

### Configuration Changes

**Before (HTTP Challenge)**:
```yaml
certificatesResolvers:
  letsencrypt:
    acme:
      email: your-email@example.com
      storage: /etc/dokploy/traefik/dynamic/acme.json
      httpChallenge:
        entryPoint: web
```

**After (DNS Challenge with OVH)**:
```yaml
certificatesResolvers:
  letsencrypt:
    acme:
      email: your-email@example.com
      storage: /etc/dokploy/traefik/dynamic/acme.json
      dnsChallenge:
        provider: ovh
        delayBeforeCheck: 10
        resolvers:
          - 1.1.1.1:53
          - 8.8.8.8:53
```

### Environment Variables Added

The script adds these environment variables to the Traefik container:
- `OVH_ENDPOINT`: API endpoint (ovh-eu, ovh-ca, ovh-us)
- `OVH_APPLICATION_KEY`: Your OVH application key
- `OVH_APPLICATION_SECRET`: Your OVH application secret
- `OVH_CONSUMER_KEY`: Your OVH consumer key

---

## Troubleshooting

### Certificate Not Generated

**Check logs for DNS errors**:
```bash
docker logs dokploy-traefik 2>&1 | grep -i error
docker logs dokploy-traefik 2>&1 | grep -i ovh
```

**Common issues**:
- Invalid OVH credentials → Verify in OVH API console
- Wrong endpoint → Check if using ovh-eu, ovh-ca, or ovh-us
- DNS propagation delay → Wait 2-5 minutes and check logs
- Domain not managed by OVH → DNS challenge requires OVH DNS

### Container Fails to Start

**Check container status**:
```bash
docker ps -a | grep traefik
docker logs dokploy-traefik
```

**Common issues**:
- Port conflict → Check if ports 80/443 are already in use
- Configuration syntax error → Restore from backup
- Missing volumes → Verify /etc/dokploy/traefik exists

### API Permission Denied

**Error**: `Error 403: This credential is not valid`

**Solution**:
1. Verify API credentials at https://api.ovh.com/createToken/
2. Ensure these permissions are granted:
   - GET /domain/zone/*
   - POST /domain/zone/*
   - DELETE /domain/zone/*
3. Regenerate credentials if needed

### Rate Limit Exceeded

**Error**: `Error 429: Too many requests`

**Solution**:
- Let's Encrypt rate limits: 5 failed validations per hour
- Wait 1 hour before retrying
- Use staging environment for testing (modify script)

---

## Rollback Procedure

If something goes wrong, you can rollback to the previous configuration:

```bash
# Find your backup
ls -lt /etc/dokploy/traefik/*.backup.*

# Restore configuration
sudo cp /etc/dokploy/traefik/traefik.yml.backup.YYYYMMDD_HHMMSS \
     /etc/dokploy/traefik/traefik.yml

# Restore ACME storage (if needed)
sudo cp /etc/dokploy/traefik/dynamic/acme.json.backup.YYYYMMDD_HHMMSS \
     /etc/dokploy/traefik/dynamic/acme.json

# Restart Traefik
docker restart dokploy-traefik
```

---

## Wildcard Certificates

DNS challenge is required for wildcard certificates.

### Configure Wildcard in Dynamic Config

Edit your service configuration (`/etc/dokploy/traefik/dynamic/dokploy.yml`):

```yaml
http:
  routers:
    dokploy-router-app-secure:
      rule: Host(`maquette-01.lepervier.org`) || Host(`*.lepervier.org`)
      service: dokploy-service-app
      entryPoints:
        - websecure
      tls:
        certResolver: letsencrypt
        domains:
          - main: lepervier.org
            sans:
              - "*.lepervier.org"
```

Reload Traefik:
```bash
docker restart dokploy-traefik
```

---

## Security Best Practices

1. **Protect OVH Credentials**:
   ```bash
   # Store in environment file (never commit to git)
   cat > ~/ovh-credentials.env << EOF
   OVH_APP_KEY=your_app_key
   OVH_APP_SECRET=your_app_secret
   OVH_CONSUMER_KEY=your_consumer_key
   EOF
   chmod 600 ~/ovh-credentials.env
   ```

2. **Use Secrets Management**:
   - Docker Swarm secrets (if using Swarm mode)
   - HashiCorp Vault
   - AWS Secrets Manager

3. **Limit API Token Validity**:
   - Set expiration date when creating tokens
   - Rotate credentials periodically (every 6-12 months)

4. **Monitor ACME Storage**:
   ```bash
   # Set proper permissions
   sudo chmod 600 /etc/dokploy/traefik/dynamic/acme.json
   sudo chown root:root /etc/dokploy/traefik/dynamic/acme.json
   ```

---

## Advanced Configuration

### Custom DNS Resolvers

Modify the script or configuration to use custom DNS resolvers:

```yaml
dnsChallenge:
  provider: ovh
  delayBeforeCheck: 10
  resolvers:
    - 1.1.1.1:53      # Cloudflare
    - 8.8.8.8:53      # Google
    - 9.9.9.9:53      # Quad9
```

### Staging Environment (Testing)

For testing, use Let's Encrypt staging environment to avoid rate limits:

```yaml
certificatesResolvers:
  letsencrypt:
    acme:
      email: your-email@example.com
      storage: /etc/dokploy/traefik/dynamic/acme.json
      caServer: https://acme-staging-v02.api.letsencrypt.org/directory
      dnsChallenge:
        provider: ovh
```

**Note**: Staging certificates are not trusted by browsers (for testing only)

---

## Monitoring & Maintenance

### Certificate Expiration

Let's Encrypt certificates are valid for 90 days. Traefik automatically renews them 30 days before expiration.

**Monitor renewals**:
```bash
# Check certificate expiration
echo | openssl s_client -servername your-domain.com -connect your-domain.com:443 2>/dev/null | openssl x509 -noout -dates

# Check Traefik logs for renewal
docker logs dokploy-traefik | grep -i renew
```

### Automated Monitoring Script

```bash
#!/bin/bash
# check-cert-expiry.sh

DOMAIN="your-domain.com"
DAYS_WARNING=14

EXPIRY=$(echo | openssl s_client -servername $DOMAIN -connect $DOMAIN:443 2>/dev/null | \
         openssl x509 -noout -enddate | cut -d= -f2)

EXPIRY_EPOCH=$(date -d "$EXPIRY" +%s)
NOW_EPOCH=$(date +%s)
DAYS_LEFT=$(( ($EXPIRY_EPOCH - $NOW_EPOCH) / 86400 ))

if [ $DAYS_LEFT -lt $DAYS_WARNING ]; then
    echo "WARNING: Certificate expires in $DAYS_LEFT days!"
    # Send alert (email, Slack, etc.)
else
    echo "Certificate valid for $DAYS_LEFT more days"
fi
```

---

## Related Documentation

- [Traefik OVH DNS Documentation](https://doc.traefik.io/traefik/https/acme/#providers)
- [Let's Encrypt Rate Limits](https://letsencrypt.org/docs/rate-limits/)
- [OVH API Documentation](https://api.ovh.com/)
- [Dokploy Architecture Documentation](./architecture/)

---

## Support

If you encounter issues:

1. Check the troubleshooting section above
2. Review Traefik logs: `docker logs dokploy-traefik`
3. Verify OVH credentials and permissions
4. Check Dokploy documentation
5. Open an issue on GitHub with logs and configuration (redact credentials!)

---

**Last Updated**: 2024-12-31  
**Script Version**: 1.0  
**Traefik Version**: 3.6.1
