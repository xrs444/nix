# vsftpd FTP Service

Lightweight FTP server configuration for receiving backups.

## Configuration

### xsvr1 - Omada Backup FTP

Provides FTP access for Omada controller backups with read/write permissions for retention management.

**User:** `omada-ftp`
**Directory:** `/zfs/systembackups/omada`
**Access:** Read/Write (chrooted to home directory)

## Setting Up Password

Before deploying, you need to create a sops secret with the password hash:

1. Generate a password hash:

```bash
mkpasswd -m sha-512
```

1. Create the sops secret file:

```bash
cd nix/secrets
# Create omada-ftp.yaml with the following structure:
cat > omada-ftp.yaml <<EOF
hashed_password: YOUR_GENERATED_HASH_HERE
EOF

# Encrypt it with sops
sops -e -i omada-ftp.yaml
```

The secret is automatically loaded by [xsvr1.nix](xsvr1.nix:5-9) using `hashedPasswordFile`.

## Firewall Ports

- **TCP 21**: FTP control connection
- **TCP 50000-50100**: FTP passive mode data connections

## Omada Configuration

Configure Omada to backup to:

- **Protocol:** FTP
- **Server:** xsvr1's IP address
- **Port:** 21
- **Username:** omada-ftp
- **Password:** [Your generated password]
- **Path:** `/` (user is chrooted to backup directory)

## Security Notes

- User is chrooted to `/zfs/systembackups/omada`
- Anonymous access is disabled
- Only the `omada-ftp` user can login
- SSL/TLS is disabled (consider enabling if FTP is exposed outside local network)
