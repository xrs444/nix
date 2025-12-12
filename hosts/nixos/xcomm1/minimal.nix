{
  pkgs,
  lib,
  inputs,
  ...
}:
{
  imports = [
    ../../base-nixos.nix
  ];
  # Minimal stub for xcomm1-minimal; add overrides if needed

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = false;

  users.users.builder = {
    isNormalUser = true;
    home = "/home/builder";
    shell = pkgs.bash;
    group = "builder";
    openssh.authorizedKeys.keys = [
      # ...existing code...
    ];
    ignoreShellProgramCheck = true;
  };
  users.groups.builder = { };
}
