# Kanidm on Darwin (macOS) - Setup Notes

## Current Status

The kanidm configuration has been updated to support both NixOS and Darwin systems, but there are important limitations on macOS:

## What Works

- ✅ Kanidm client tools are installed (`kanidm` command)
- ✅ Client configuration file is created at `/etc/kanidm/config`
- ✅ Basic SSH configuration is provided

## Limitations on Darwin

- ❌ **No automatic PAM integration**: Unlike NixOS, macOS doesn't have built-in kanidm PAM support
- ❌ **No automatic user lookup**: NSS modules for kanidm aren't available on macOS
- ❌ **No automatic sudo integration**: Sudo rules can't directly reference kanidm users
- ❌ **Manual SSH setup required**: SSH key management must be configured manually

## Manual Setup Required for Darwin

### 1. Authentication Workflow
```bash
# Users need to authenticate with kanidm first
kanidm login
```

### 2. SSH Key Management
Users will need to either:
- Configure SSH keys through the kanidm web interface
- Use SSH agent forwarding
- Set up SSH certificates (if your kanidm server supports them)

### 3. Local User Accounts
For sudo access, you may need to create local user accounts that mirror your kanidm users:

```bash
# Example: Create local user for kanidm user 'xrs444'
sudo dscl . -create /Users/xrs444
sudo dscl . -create /Users/xrs444 UserShell /bin/zsh
sudo dscl . -create /Users/xrs444 RealName "xrs444"
sudo dscl . -create /Users/xrs444 UniqueID 501
sudo dscl . -create /Users/xrs444 PrimaryGroupID 80
sudo dscl . -create /Users/xrs444 NFSHomeDirectory /Users/xrs444
sudo dscl . -append /Groups/admin GroupMembership xrs444
```

## Recommended Approach for Darwin

For better kanidm integration on macOS, consider:

1. **Use Home Manager**: Configure per-user SSH settings through Home Manager
2. **External Tools**: Use tools like `kanidm-ssh-authorizedkeys` for SSH key management
3. **Manual PAM**: Configure PAM modules manually if needed
4. **Hybrid Approach**: Use local accounts with kanidm for authentication

## Future Improvements

To improve Darwin support, we could:
- Add custom PAM modules for kanidm
- Create launchd services for kanidm integration  
- Develop Darwin-specific user management scripts
- Integrate with macOS keychain services