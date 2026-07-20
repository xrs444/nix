# Summary: Syncthing service for xrs444's Obsidian vault, joining the existing
# mesh (xsvr1 hub + xlt1-t darwin laptop). Brings xdt1-t to parity with
# xlt1-t, which runs Syncthing via the `syncthing-app` brew cask
# (modules/packages-darwin/brew-packages.nix) — that side isn't nix-declared,
# so the folder/device IDs below were captured by hand from xlt1-t's live
# config.xml rather than shared as nix values.
#
# Device/folder IDs are not secret (Syncthing device IDs are public keys;
# folder IDs are just labels) so they're plain text here, not sops.
{ ... }:
{
  services.syncthing = {
    enable = true;
    user = "xrs444";
    group = "users";
    dataDir = "/home/xrs444";
    configDir = "/home/xrs444/.config/syncthing";

    # GUI on localhost only; use SSH port-forward or the mesh's other GUIs
    # (xsvr1/xlt1-t) for remote management.
    guiAddress = "127.0.0.1:8384";

    # Declare exactly what this host needs to know — the two other
    # nix-managed devices in the mesh. Neither xsvr1's nor xlt1-t's
    # Syncthing is nix-declared, so this can't be a shared value; the IDs
    # were read from xlt1-t's config.xml on 2026-07-19.
    settings = {
      devices = {
        xsvr1 = {
          id = "BMTUKUC-2EHB5GN-WTM2QFG-WMGNNUC-3EBYPX7-BTHGYX5-7C6SU72-FAEU7AI";
          # xsvr1 is the mesh hub/introducer on every other member's config;
          # mirror that here so xdt1-t can pick up folder shares xsvr1
          # already knows about (e.g. Munin) without hand-adding each one.
          introducer = true;
        };
        xlt1-t = {
          id = "KR5364I-V6A6WVX-JXQS3XX-IQROL3Q-E654SM3-UVYOZZ3-L5XMEQ7-IOUHKQV";
        };
      };

      folders."xrs444-obsidian" = {
        label = "Obsidian";
        path = "/home/xrs444/Documents/obsidian";
        devices = [
          "xsvr1"
          "xlt1-t"
        ];
      };
    };
  };

  # services.syncthing.openDefaultPorts opens the global firewall; this repo's
  # convention on xdt1-t is per-interface rules (see default.nix's
  # networking.firewall.interfaces.enp8s0.allowedTCPPorts), so open the sync
  # transport (22000 TCP/UDP) and local discovery (21027 UDP) the same way
  # instead of enabling that option.
  networking.firewall.interfaces.enp8s0 = {
    allowedTCPPorts = [ 22000 ];
    allowedUDPPorts = [
      22000
      21027
    ];
  };

  # BOOTSTRAP NOTE (one-time, manual, can't be pre-declared): xdt1-t
  # generates its own Syncthing device ID (cert/key pair) the first time
  # this service starts — that ID doesn't exist before deploy, so it can't
  # be added to xsvr1's or xlt1-t's device lists ahead of time. After the
  # first deploy: read the new ID (`syncthing --device-id` or the GUI at
  # 127.0.0.1:8384), then add it as a device — and share the
  # "xrs444-obsidian" folder with it — on xsvr1 (and/or xlt1-t) via their
  # own GUIs, since neither is nix-managed. This is normal Syncthing device
  # pairing (mutual consent by design), not something to script around.
}
