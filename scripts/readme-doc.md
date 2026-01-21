# scripts

This directory contains utility scripts and the project's justfile for managing the HomeProd Nix infrastructure.

## Justfile

The primary interface for common operations is the **justfile**, which consolidates most scripting tasks.

See [JUSTFILE.md](../JUSTFILE.md) for complete documentation.

### Quick Start

```bash
# From the nix repository root
just --justfile scripts/justfile --list

# Create an alias for convenience
alias j='just --justfile scripts/justfile'
j build xsvr1
```

## Remaining Scripts

These specialized scripts remain for advanced use cases not covered by the justfile:

### new-host.sh

Full-featured host creation script with:

- Age key generation for SOPS
- Automatic `.sops.yaml` updates
- Secret rekeying
- Host directory structure creation
- Hardware configuration templates

Use this for creating new hosts when you need full SOPS integration. A simplified version is available via `just new-host`.

### nix-sh.fish

Fish shell utility function for choosing Nix development shells.

### init-testing-workflow.fish

Helper script for initializing testing workflows.

## Removed Scripts

The following scripts have been consolidated into the justfile and removed:

- `build-and-cache-xsvr1-hosts.sh` → `just build-and-cache-all`
- `deploy-xdash1.sh` → `just deploy-xdash1`
- `deploy-xdash1-simple.sh` → `just deploy-xdash1-simple`
- `deploy-xdash1-nokexec.sh` → Use `just deploy-xdash1-simple`
- `deploy-xdash1-manual.sh` → Use `just deploy-xdash1`
- `deploy-xdash1-with-kexec-tarball.sh` → Use `just deploy-xdash1`
- `write-sdcard.sh` → `just write-sdcard`
- `extract-thomas-local-key.sh` → `just extract-thomas-local-key`
- `../hosts/nixable/scripts/deploy-ssh-key.sh` → `just deploy-ssh-key`

Use the justfile commands for all these operations going forward.
