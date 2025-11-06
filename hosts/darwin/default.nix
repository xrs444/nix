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

  # Set system state version
  system.stateVersion = 5;
  nix.enable = false;

    # Configure nixpkgs
  nixpkgs = {
    hostPlatform = lib.mkDefault "${platform}";

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