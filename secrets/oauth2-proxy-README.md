# OAuth2 Proxy Secrets Setup

This file contains instructions for creating the `oauth2-proxy.yaml` secrets file for the monitoring reverse proxy.

## Initial Setup

1. **Create the OAuth2 client in Kanidm** (see the reverse-proxy setup documentation)

2. **Generate a cookie secret**:
   ```bash
   openssl rand -base64 32
   ```

3. **Create the secrets file**:
   ```bash
   cd /Users/xrs444/Repositories/HomeProd/nix

   # Create a new encrypted secrets file
   sops secrets/oauth2-proxy.yaml
   ```

4. **Add the following content** (replace values with your actual secrets):
   ```yaml
   client_id: "monitoring"
   client_secret: "your-kanidm-oauth2-client-secret-here"
   cookie_secret: "your-generated-cookie-secret-here"
   ```

5. **Save and exit** the sops editor

## Getting the Kanidm OAuth2 Client Secret

After creating the OAuth2 client in Kanidm (see setup docs), retrieve the secret with:

```bash
# SSH to xsvr1 or xsvr2 (Kanidm hosts)
ssh thomas-local@xsvr1.lan

# Login as admin
export KANIDM_PASSWORD=$(sudo cat /run/secrets/kanidm_idm_admin_password)
echo $KANIDM_PASSWORD | kanidm login -D idm_admin

# View the OAuth2 client configuration
kanidm system oauth2 get monitoring

# The basic_secret value is what you need for client_secret
```

## Verifying the File

After creating the file, verify it can be decrypted:

```bash
sops -d secrets/oauth2-proxy.yaml
```

You should see your three secrets in plain text.

## Security Notes

- The `cookie_secret` must be 32 bytes (will be base64 encoded, so 44 characters)
- Never commit unencrypted secrets to git
- The file will automatically be encrypted by sops using the age keys defined in `.sops.yaml`
