# Reverse Proxy Setup for xsvr1 Monitoring Services

This document describes the lightweight reverse proxy setup for xsvr1 that provides secure, authenticated access to monitoring and management services like Prometheus, Alertmanager, Grafana, and Cockpit.

## Architecture Overview

The reverse proxy uses:
- **Nginx** - Lightweight reverse proxy with SSL/TLS termination
- **OAuth2-proxy** - Kanidm SSO integration for authentication
- **Let's Encrypt** - Automatic SSL certificate management
- **Kanidm** - Identity provider (already deployed)

## Services Exposed

The following services are accessible via the reverse proxy with Kanidm SSO:

| Service | URL | Port | Description |
|---------|-----|------|-------------|
| Prometheus | https://prometheus.xrs444.net | 9090 | Metrics database and query interface |
| Alertmanager | https://alertmanager.xrs444.net | 9093 | Alert routing and management |
| Grafana | https://grafana.xrs444.net | 3000 | Metrics visualization dashboards |
| Cockpit | https://cockpit.xrs444.net | 9091 | System management interface |
| Auth | https://auth.xrs444.net | 4180 | OAuth2 callback endpoint |

## Prerequisites

1. xsvr1 is already configured with:
   - Let's Encrypt primary role
   - Kanidm primary role
   - Monitoring server role
   - Cockpit role

2. DNS records for the new subdomains point to xsvr1's IP

3. You have admin access to Kanidm

## Setup Steps

### Step 1: Create Kanidm OAuth2 Client

SSH to xsvr1 and create the OAuth2 client:

```bash
# SSH to xsvr1
ssh thomas-local@xsvr1.lan

# Login as Kanidm admin
export KANIDM_PASSWORD=$(sudo cat /run/secrets/kanidm_idm_admin_password)
echo $KANIDM_PASSWORD | kanidm login -D idm_admin

# Create the OAuth2 client for monitoring services
kanidm system oauth2 create monitoring "Monitoring Services" https://auth.xrs444.net/oauth2/callback

# Enable PKCE (required by Kanidm)
kanidm system oauth2 update-scope-map monitoring monitoring openid profile email

# Add all redirect URLs for the services
kanidm system oauth2 add-redirect-url monitoring https://auth.xrs444.net/oauth2/callback
kanidm system oauth2 add-redirect-url monitoring https://prometheus.xrs444.net/oauth2/callback
kanidm system oauth2 add-redirect-url monitoring https://alertmanager.xrs444.net/oauth2/callback
kanidm system oauth2 add-redirect-url monitoring https://grafana.xrs444.net/oauth2/callback
kanidm system oauth2 add-redirect-url monitoring https://cockpit.xrs444.net/oauth2/callback

# Display the client configuration and note the basic_secret
kanidm system oauth2 get monitoring
```

Save the `basic_secret` value - you'll need it in the next step.

### Step 2: Create OAuth2 Secrets File

On your local machine (xlt1-t):

```bash
cd /Users/xrs444/Repositories/HomeProd/nix

# Generate a cookie secret
COOKIE_SECRET=$(openssl rand -base64 32)
echo "Cookie secret: $COOKIE_SECRET"

# Create the encrypted secrets file
sops secrets/oauth2-proxy.yaml
```

In the sops editor, add:

```yaml
client_id: "monitoring"
client_secret: "paste-the-basic_secret-from-kanidm-here"
cookie_secret: "paste-the-cookie-secret-generated-above"
```

Save and exit the editor.

Verify the file:
```bash
sops -d secrets/oauth2-proxy.yaml
```

### Step 3: Update .sops.yaml (if needed)

Ensure the new secrets file is included in `.sops.yaml`:

```bash
grep -A5 "oauth2-proxy.yaml" .sops.yaml
```

If not present, add it to the `creation_rules` section.

### Step 4: Deploy to xsvr1

The configuration is already in place (reverse-proxy role added to flake.nix). Deploy it:

```bash
cd /Users/xrs444/Repositories/HomeProd/nix

# Build the configuration
nix build .#nixosConfigurations.xsvr1.config.system.build.toplevel

# Deploy to xsvr1
nixos-rebuild switch --flake .#xsvr1 --target-host thomas-local@xsvr1.lan --use-remote-sudo
```

### Step 5: Verify Services

After deployment, check that services are running on xsvr1:

```bash
ssh thomas-local@xsvr1.lan

# Check OAuth2 proxy
sudo systemctl status oauth2-proxy

# Check Nginx
sudo systemctl status nginx

# View OAuth2 proxy logs
sudo journalctl -u oauth2-proxy -f

# View Nginx logs
sudo journalctl -u nginx -f
```

### Step 6: Test Access

1. **Test Prometheus**: Navigate to https://prometheus.xrs444.net
   - You should be redirected to Kanidm for login
   - After authentication, you should see the Prometheus UI

2. **Test Alertmanager**: Navigate to https://alertmanager.xrs444.net

3. **Test Grafana**: Navigate to https://grafana.xrs444.net

4. **Test Cockpit**: Navigate to https://cockpit.xrs444.net

## Troubleshooting

### OAuth2 Authentication Fails

Check OAuth2 proxy logs:
```bash
ssh thomas-local@xsvr1.lan
sudo journalctl -u oauth2-proxy -n 100
```

Common issues:
- **Invalid redirect URL**: Ensure all redirect URLs are added to the Kanidm OAuth2 client
- **Missing PKCE**: OAuth2 proxy is configured with `--code-challenge-method=S256`
- **Cookie secret too short**: Must be 32 bytes (44 characters base64-encoded)

### Certificate Issues

Check Let's Encrypt certificate status:
```bash
ssh thomas-local@xsvr1.lan
sudo ls -la /var/lib/acme/
sudo systemctl status acme-prometheus.xrs444.net.service
```

Force certificate renewal if needed:
```bash
sudo systemctl start acme-prometheus.xrs444.net.service
```

### Nginx Configuration Errors

Test Nginx configuration:
```bash
ssh thomas-local@xsvr1.lan
sudo nginx -t
```

View Nginx logs:
```bash
sudo journalctl -u nginx -n 100
```

### Service Not Accessible

1. Check firewall:
   ```bash
   ssh thomas-local@xsvr1.lan
   sudo iptables -L -n | grep 443
   ```

2. Check Nginx is listening:
   ```bash
   sudo ss -tlnp | grep :443
   ```

3. Check DNS resolution:
   ```bash
   dig prometheus.xrs444.net
   ```

### OAuth2 Proxy Cannot Reach Kanidm

Verify network connectivity:
```bash
ssh thomas-local@xsvr1.lan
curl -v https://idm.xrs444.net/.well-known/openid-configuration
```

## Security Considerations

1. **Access Control**: Only authenticated Kanidm users can access the services
2. **SSL/TLS**: All traffic is encrypted with Let's Encrypt certificates
3. **PKCE**: OAuth2 uses PKCE (Proof Key for Code Exchange) for enhanced security
4. **Cookie Security**: Cookies are marked as secure and limited to *.xrs444.net domain
5. **Secrets Management**: All secrets are encrypted with sops-nix

## Granting User Access

To grant a user access to monitoring services:

```bash
ssh thomas-local@xsvr1.lan

# Login as admin
export KANIDM_PASSWORD=$(sudo cat /run/secrets/kanidm_idm_admin_password)
echo $KANIDM_PASSWORD | kanidm login -D idm_admin

# Option 1: Grant access to a specific user
kanidm group add-members monitoring username

# Option 2: Grant access to all members of an existing group
kanidm system oauth2 update-sup-scope-map monitoring existing_group openid profile email
```

## Configuration Files

The reverse proxy is configured through the following files:

- **OAuth2 Proxy Module**: `nix/modules/services/oauth2-proxy/default.nix`
- **Reverse Proxy Module**: `nix/modules/services/reverse-proxy/default.nix`
- **Let's Encrypt Config**: `nix/modules/services/letsencrypt/default.nix`
- **Host Configuration**: `nix/flake.nix` (xsvr1 roles)
- **Secrets**: `nix/secrets/oauth2-proxy.yaml`

## Maintenance

### Updating Certificates

Certificates renew automatically via ACME. To manually renew:

```bash
ssh thomas-local@xsvr1.lan
sudo systemctl start acme-prometheus.xrs444.net.service
```

### Adding New Services

To add a new service to the reverse proxy:

1. Edit `nix/modules/services/reverse-proxy/default.nix`
2. Add the service to the `services` attribute set
3. Add the subdomain to Let's Encrypt `extraDomainNames` if needed
4. Add redirect URL to Kanidm OAuth2 client
5. Deploy to xsvr1

### Rotating OAuth2 Secrets

1. Generate new secrets in Kanidm and locally
2. Update `secrets/oauth2-proxy.yaml` with sops
3. Redeploy to xsvr1
4. Restart oauth2-proxy: `sudo systemctl restart oauth2-proxy`

## Architecture Diagram

```
Internet
    |
    | HTTPS (443)
    v
[Nginx Reverse Proxy on xsvr1]
    |
    |-- /oauth2/* --> [OAuth2-Proxy :4180] --> [Kanidm idm.xrs444.net]
    |
    |-- /* (authenticated) --> [OAuth2-Proxy :4180/auth]
                                    |
                                    v
                        +-----------+-----------+
                        |                       |
                        v                       v
            [Prometheus :9090]      [Alertmanager :9093]
                        |                       |
                        v                       v
            [Grafana :3000]         [Cockpit :9091]
```

## Related Documentation

- [Kanidm OAuth2 Setup](kubernetes-auth-setup.md)
- [Monitoring Setup](monitoring.md)
- [Let's Encrypt Configuration](letsencrypt-setup.md)
