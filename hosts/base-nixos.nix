# Base NixOS configuration shared between x86_64 and ARM platforms
{
  lib,
  inputs,
  stateVersion,
  ...
}:
{
  options = {
    minimalImage = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Build a minimal image with only comin and essential services.";
    };
  };

  imports = [
    inputs.home-manager.nixosModules.home-manager
    inputs.agenix.nixosModules.default
    inputs.sops-nix.nixosModules.sops
    inputs.disko.nixosModules.disko
    inputs.comin.nixosModules.comin
    ../modules/users/default.nix
  ];

  config = {
    time.timeZone = "America/Phoenix";
    nix.settings.experimental-features = [
      "nix-command"
      "flakes"
    ];

    # Configure sops-nix to use the age key file
    sops.age.keyFile = "/etc/ssh/sops-age-key.txt";
    sops.defaultSopsFile = "/secrets/wan-wifi.yaml";

    system.stateVersion = stateVersion;

    nixpkgs.config.allowUnfree = true;

  };
}
