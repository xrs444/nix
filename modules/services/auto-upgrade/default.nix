# Summary: NixOS module for pull-based auto-upgrade via flake, acts as a catch-up safety net for hosts that may miss push-based deployments.
# Enabled via the "auto-upgrade" hostRole. Substituters are already configured
# by the remotebuilds module (http://xsvr1.lan + https://cache.nixos.org), so
# upgrades pull pre-built closures from the local nixcache with no local compilation.
{
  hostname,
  hostRoles ? [ ],
  lib,
  ...
}:
let
  hasRole = lib.elem "auto-upgrade" hostRoles;
in
{
  config = lib.mkIf hasRole {
    system.autoUpgrade = {
      enable = true;
      # Pull from the same flake used by CI/deploy-rs
      flake = "github:xrs444/nix#${hostname}";
      # Timer fires at 04:30; Persistent = true (set by NixOS automatically for
      # OnCalendar timers) ensures missed firings run at next boot.
      dates = "04:30";
      allowReboot = false;
    };
  };
}
