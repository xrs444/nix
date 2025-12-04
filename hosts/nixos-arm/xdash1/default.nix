# Summary: NixOS ARM host configuration for xdash1, imports Orange Pi hardware, boot, network, and SD image modules.
{
  pkgs,
  hostname,
  inputs,
  ...
}:

{
  imports = [
    ../../base-nixos.nix
    ../common/default.nix
    (import (inputs.self + /modules/hardware/OrangePiZero3/default.nix))
    ../common/boot.nix
    ./network.nix
    (import (inputs.self + /modules/sdImage/custom.nix))
    inputs.sops-nix.nixosModules.sops
    # Common imports are now handled by hosts/common/default.nix
  ];
  networking.hostName = hostname;

  boot.supportedFilesystems = [
    "vfat"
    "ext4"
  ];

  environment.systemPackages = with pkgs; [
    labwc
    firefox
  ];

  programs.labwc.enable = true;

  users.users.xdash1 = {
    isNormalUser = true;
    description = "Dashboard Kiosk User";
    extraGroups = [ "video" ];
    home = "/home/xdash1";
  };

  hardware.graphics.enable = true;

  services.xserver.enable = false;
  services.displayManager.defaultSession = "labwc";
  services.displayManager.sddm.enable = false;

  services.cage = {
    enable = true;
    user = "xdash1";
    program = "${pkgs.firefox}/bin/firefox -kiosk -private-window https://hass.xrs444.net";
  };

  services.getty.autologinUser = "xdash1";

  nixpkgs.config.allowUnfree = true;

}
