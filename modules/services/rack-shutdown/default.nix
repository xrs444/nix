# Summary: Scoped shutdown wrapper + sudoers rule for the `automation` user
# (Windmill's SSH executor, nix/modules/users/automation.nix), so the
# f/sre/rack_power_off Windmill flow can issue a clean poweroff on UPS
# power-loss without broad sudo access. One host per rack member covered by
# this module — xcog1 (Mac Mini) is out of scope, it needs the equivalent
# set up via nix-darwin/macOS's own sudoers mechanism separately.
{
  hostname,
  lib,
  pkgs,
  ...
}:
let
  # Every NixOS host in the UPS-backed rack that the shutdown automation
  # should be able to power off. xswcore/xfw are network gear (not NixOS,
  # left to die on the UPS or get power-cycled directly); xcog1 is darwin.
  rackHosts = [
    "xsvr1"
    "xsvr2"
    "xsvr3"
    "xsvr4"
    "xpbx1"
    "xts1"
    "xts2"
  ];
  isRackHost = builtins.elem hostname rackHosts;

  # Fixed, no-argument command — the sudoers rule only ever permits this
  # exact clean poweroff, nothing parameterized. On xsvr1-4 (KVM hosts
  # running Talos VMs under libvirt), libvirt-guests.service already stops
  # guests gracefully as part of a normal system shutdown; the
  # rack_power_off flow additionally issues `talosctl shutdown` to each
  # Talos node *before* calling this, for a cleaner k8s-level drain first.
  rackShutdown = pkgs.writeShellScript "rack-shutdown" ''
    set -euo pipefail
    exec ${pkgs.systemd}/bin/systemctl poweroff
  '';
in
lib.mkIf isRackHost {
  # Stable /etc path (not a nix store path) so the sudoers rule doesn't need
  # a hash-wildcard and survives rebuilds without resealing anything.
  environment.etc."rack-shutdown".source = rackShutdown;

  security.sudo.extraRules = [
    {
      users = [ "automation" ];
      commands = [
        {
          command = "/etc/rack-shutdown";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];
}
