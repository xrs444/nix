{ ... }:
{
  imports = [
    ../../base-nixos.nix
    ../../../modules/packages-workstation
    ../common/hardware-amd.nix
    ../common/audio-pipewire.nix
    ../common/boot.nix
    ./network.nix
    ./desktop.nix
    ./audio.nix
    ./disks.nix
    ./hardware-nvidia.nix
    ./shares.nix
    ../../common
  ];

  networking.hostName = "xdt1-t";
  nixpkgs.config.allowUnfree = true;

  # OBS is xdt1-t only — see workstationPackages.enableObs in
  # modules/packages-workstation for the (false) default.
  workstationPackages.enableObs = true;

  # Determinate Nix ignores nix.conf for trusted-users — must be in nix.custom.conf.
  # Use extra-trusted-users so this appends to (rather than overrides) the
  # remotebuilds module's "trusted-users = root builder" line.
  environment.etc."nix/nix.custom.conf".text = ''
    extra-trusted-users = @wheel
  '';

  # Wired NIC is enp8s0 (confirmed from installer). Open monitoring exporter ports.
  networking.firewall.interfaces.enp8s0.allowedTCPPorts = [
    9080
    9100
    9633
    22000
  ];

  # Syncthing sync protocol (home-manager's services.syncthing, see
  # homemanager/common/syncthing.nix). Host-specific rather than in the
  # shared common module since the interface name (enp8s0) isn't guaranteed
  # to match on a future host running the same per-user module.
  networking.firewall.interfaces.enp8s0.allowedUDPPorts = [
    22000
    21027
  ];

  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "ahci"
    "usb_storage"
    "sd_mod"
  ];

  # nvme must be in kernelModules (not just availableKernelModules) so it is
  # loaded before systemd-initrd attempts to mount the root filesystem.
  boot.initrd.kernelModules = [ "nvme" ];

  # obs-websocket password for xrs444's home-manager OBS config (apps/obs.nix).
  # xdt1-t only — OBS is only installed here.
  sops.secrets."obs-websocket-password" = {
    sopsFile = ../../../secrets/obs-websocket.yaml;
    key = "obs_websocket_password";
    owner = "xrs444";
    group = "xrs444";
    mode = "0400";
  };

  # Same password, also delivered as a plain text file for external tooling
  # that expects it at a fixed path.
  sops.secrets."obs-websocket-password-pwdfile" = {
    sopsFile = ../../../secrets/obs-websocket.yaml;
    key = "obs_websocket_password";
    owner = "xrs444";
    group = "xrs444";
    mode = "0400";
    path = "/home/xrs444/.pwd/obs";
  };
}
