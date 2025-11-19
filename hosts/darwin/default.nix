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
    ../../modules/packages-common/default.nix
    ../../modules/packages-darwin/default.nix
    ../../modules/packages-darwin/brew-packages.nix
    ../../modules/packages-workstation/default.nix
  ];


  # Set system state version
  system.stateVersion = 5;
  nix = {
    enable = false;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

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
    shell = pkgs.fish;
  };
}
