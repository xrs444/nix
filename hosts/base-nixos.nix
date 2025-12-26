# Summary: Base NixOS configuration shared by x86_64 and ARM hosts, sets options and imports core modules.
# Base NixOS configuration shared between x86_64 and ARM platforms
{
  inputs,
  stateVersion ? "25.05",
  ...
}:
{
  imports = [
    inputs.home-manager.nixosModules.home-manager
    inputs.agenix.nixosModules.default
    inputs.sops-nix.nixosModules.sops
    inputs.disko.nixosModules.disko
    inputs.comin.nixosModules.comin
    ../modules/users/default.nix
    ../modules/packages-nixos/default.nix
    ../modules/services/default.nix
  ];

  time.timeZone = "America/Phoenix";
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Configure sops-nix to use the age key file
  sops.age.keyFile = "/etc/ssh/sops-age-key.txt";

  system.stateVersion = stateVersion;
  nixpkgs.config.allowUnfree = true;
}
