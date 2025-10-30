{
  config,
  hostname,
  inputs,
  lib,
  outputs,
  pkgs,
  platform,
  stateVersion,
  username,
  desktop,
  ...
}:
{
  imports = [
    # Import host-specific configuration
    ./${hostname}
    # Import common cache configuration
    ../common
    # Import Darwin-specific modules
    ../../modules/packages-darwin
  ];

  # Enable the Nix daemon
  services.nix-daemon.enable = true;

  # Core nix settings are in ../common

  # Set system state version
  system.stateVersion = 5;

    # Configure nixpkgs
  nixpkgs = {
    hostPlatform = lib.mkDefault "${platform}";
    # overlays and config are set in ../common
  };

  # Basic system configuration
  system.defaults = {
    dock.autohide = true;
    finder.AppleShowAllExtensions = true;
    finder.FXPreferredViewStyle = "clmv";
  };

  # Enable home-manager integration
  users.users.${username} = {
    name = username;
    home = "/Users/${username}";
  };
}