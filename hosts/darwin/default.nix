# Summary: Darwin/macOS host configuration, imports common and platform-specific package modules.
{
  lib,
  pkgs,
  platform,
  username,
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
    settings = {
      trusted-users = [
        "@admin"
        username
      ];
    };
  };

  # Configure nixpkgs
  nixpkgs = {
    hostPlatform = lib.mkDefault "${platform}";

  };

  users.users.${username} = {
    name = username;
    home = "/Users/${username}";
    shell = pkgs.fish;
  };
}
