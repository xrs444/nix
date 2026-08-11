# Summary: Base NixOS configuration shared by x86_64 and ARM hosts, sets options and imports core modules.
# Base NixOS configuration shared between x86_64 and ARM platforms
{
  inputs,
  lib,
  stateVersion ? "25.05",
  hostRoles ? [ ],
  generateManCache ? false,
  hostname ? null,
  username ? null,
  desktop ? null,
  platform ? null,
  enableHomeManager ? true,
  minimalImage ? false,
  ...
}:
{
  # Make hostRoles available to all imported modules
  _module.args = {
    inherit hostRoles;
  };

  imports = [
    inputs.home-manager.nixosModules.home-manager
    inputs.agenix.nixosModules.default
    inputs.sops-nix.nixosModules.sops
    inputs.disko.nixosModules.disko
    ../modules/users/default.nix
    ../modules/packages-nixos/default.nix
    ../modules/services/default.nix
  ];

  # Integrated Home Manager: activates as part of `nixos-rebuild switch`, so it
  # rides the same push (CI deploy.yml) and pull (auto-upgrade role) paths the
  # system config already uses — no separate `home-manager switch` or timer
  # needed. inputs.home-manager.nixosModules.home-manager was imported above
  # but never configured (no `home-manager.users.*`), which is why it did
  # nothing until now. Skipped for minimal installer images (before deploy-rs
  # has run) and for hosts with enableHomeManager = false (servers with no
  # interactive user, e.g. xts1/xts2/cmrpi1/xpbx1/vocibuild).
  home-manager = lib.mkIf (enableHomeManager && !minimalImage && username != null) {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
    sharedModules = [
      inputs.catppuccin.homeModules.catppuccin
      {
        catppuccin.autoEnable = lib.mkDefault false;
        catppuccin.enable = lib.mkDefault true;
      }
    ];
    extraSpecialArgs = {
      inherit inputs stateVersion desktop platform;
      hostName = hostname;
      inherit username;
    };
    users.${username} = ../homemanager;
  };

  time.timeZone = "America/Phoenix";
  console.keyMap = "us";
  services.udisks2.enable = true;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nix.settings.download-buffer-size = 134217728; # 128 MiB

  # Automated garbage collection (NixOS only)
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # Automatically hard-link identical files in the store after each build
  nix.settings.auto-optimise-store = true;

  # Configure sops-nix to use the age key file
  sops.age.keyFile = "/etc/ssh/sops-age-key.txt";

  system.stateVersion = stateVersion;
  nixpkgs.config.allowUnfree = true;

  documentation.man.cache.enable = generateManCache;
}
