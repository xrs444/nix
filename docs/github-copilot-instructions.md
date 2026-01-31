# Copilot Instructions for HomeProd Nix Codebase

## Project Overview
This repository manages NixOS and Darwin configurations for a multi-host home and lab environment. It includes:
- NixOS server/workstation configs (xsvr1, xsvr2, xsvr3, etc.)
- Mac and user workstation configs
- Common modules for hardware, boot, audio, performance, and services
- Service definitions (e.g., letsencrypt, homeassistant, tailscale)
- Overlay and package definitions for custom/unstable packages

## Architecture & Structure
- **hosts/**: Per-host configs, grouped by OS (nixos, darwin, nixos-arm)
- **homemanager/**: User-level configs, desktop/shell settings, per-user overrides
- **modules/**: Reusable service and package modules, organized by platform/service
- **pkgs/** & **overlays/**: Custom packages and overlays
- **scripts/**: Deployment and utility scripts for provisioning and maintenance
- **secrets/**: YAML files for sensitive config (do not expose in PRs)

## Key Patterns & Conventions
- **Module Imports**: Use `imports = [ ... ];` to compose configs. Common modules use `lib.mkDefault` for overridable defaults.
- **Host-Specific Overrides**: Override defaults with `lib.mkForce` in host configs.
- **Service Modules**: Each service (e.g., letsencrypt, tailscale) is a module in `modules/services/` and imported as needed.
- **Hardware Profiles**: AMD/Intel/ARM hardware modules in `hosts/nixos/common/` and `hosts/nixos-arm/common/`.
- **User Configs**: Per-user configs in `homemanager/users/`.

## Developer Workflows
- **Build NixOS Image**: `sudo nix build .#nixosConfigurations.<hostname>.config.system.build.sdImage -L --show-trace`
- **Deploy Scripts**: Use scripts in `scripts/` for host provisioning (e.g., `deploy-xdash1.sh`).
- **Secrets Management**: Reference YAML files in `secrets/` for sensitive data; do not hardcode secrets.
- **Testing**: No formal test suite; validate by building and deploying configs.

## Integration Points
- **ZFS Storage**: Storage arrays managed via host configs and service modules.
- **Omada, Tailscale**: Integrated as NixOS modules/services.
- **xsvr1, xsvr2, xsvr3**: each run a Talos VM for kubernetes.
- **xsvr1** runs HomeAssistant and Omada controller VMs.
## Examples
- To add a new service, create a module in `modules/services/` and import it in the relevant host config.
- To override a default (e.g., CPU governor):
  ```nix
  powerManagement.cpuFreqGovernor = lib.mkForce "ondemand";
  ```
- To add a user config: create a file in `homemanager/users/` and import in the main homemanager config.

## References
- See `README.md` in the repo root and in `hosts/nixos/common/` and `hosts/nixos-arm/common/` for more details on module usage and hardware profiles.

---

**If any section is unclear or missing important project-specific details, please provide feedback so this guide can be improved.**
