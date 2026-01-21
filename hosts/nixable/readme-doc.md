# Nixable Hosts

This directory contains [nixible](https://nixible.projects.tf/) configurations for non-NixOS hosts that cannot run Nix code directly.

## Structure

- `common/` - Shared configuration, collections, and variables used across all nixable hosts
- `xdt1-t/` - Configuration for xdt1-t (Bazzite host)
- `xdt2-g/` - Configuration for xdt2-g (Bazzite host)
- `xdt3-r/` - Configuration for xdt3-r (Bazzite host)

## About Nixible

Nixible is "Ansible but with Nix" - it allows you to define Ansible playbooks, inventories, and collections as type-safe Nix expressions. This provides:

- Type-safe playbook definitions using Nix's module system
- Reproducible Ansible environments with locked dependencies
- Automatic collection management from Ansible Galaxy

## Host Details

These hosts run Bazzite OS (an immutable Fedora-based gaming distribution) and therefore cannot run NixOS configurations directly. Nixible allows us to manage them declaratively using Ansible while maintaining reproducibility through Nix.

## Initial Setup

Before you can use Ansible to manage these hosts, you need to set up SSH access for the `ansible` user.

### Deploy SSH Key to Hosts

Use the justfile command to set up the ansible user and deploy your SSH key:

```bash
# From the nix repository root
# Deploy to a single host (will prompt for initial user's password if needed)
just --justfile scripts/justfile deploy-ssh-key xdt1-t

# Deploy with a specific initial user
just --justfile scripts/justfile deploy-ssh-key xdt2-g thomas-local

# Deploy with a custom SSH key
just --justfile scripts/justfile deploy-ssh-key xdt3-r thomas-local ~/.ssh/id_rsa.pub

# Or create an alias for convenience
alias j='just --justfile scripts/justfile'
j deploy-ssh-key xdt1-t
```

The command will:

1. Test SSH connectivity to the target host
2. Create the `ansible` user with sudo privileges
3. Deploy your SSH public key for passwordless authentication
4. Verify the setup by testing the ansible user connection

After running this script, the host will be ready for Ansible management.

## Usage

Each host configuration should be added to the flake.nix as a package:

```nix
packages.xdt1-t = nixible_lib.mkNixibleCli ./hosts/nixable/xdt1-t/default.nix;
```

Then run with:

```bash
nix run .#xdt1-t
```

## Configuration Pattern

Each host folder contains a `default.nix` that:

1. Imports common configuration from `common/default.nix`
2. Defines host-specific inventory with the `ansible` user
3. Defines host-specific playbooks and tasks

The common folder contains:

- `default.nix` - Shared Ansible collections and variables
- `ansible-user.nix` - Playbook for setting up the ansible user (used by the deployment script)
- `thomas-local-user.nix` - Standalone playbook for deploying the thomas-local user
- `install-just.nix` - Standalone playbook for installing the just command runner

## Deployed Users

### Ansible User

All hosts use a dedicated `ansible` user for automation with:

- Passwordless sudo access via `/etc/sudoers.d/ansible`
- SSH key-based authentication
- Membership in the `wheel` group

### thomas-local User

The `thomas-local` user is automatically deployed to all Bazzite hosts with:

- Sudo access via `wheel` group membership
- SSH key-based authentication (same keys as NixOS hosts)
- Bash shell
- Home directory at `/home/thomas-local`

The thomas-local user allows you to access Bazzite hosts using the same SSH keys and credentials as your NixOS hosts, providing a consistent authentication experience across your infrastructure.
