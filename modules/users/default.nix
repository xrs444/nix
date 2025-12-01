{ config, lib, pkgs, ... }:
{
  imports = [
    ./thomas-local.nix
    ./builder.nix
    ./acme.nix
  ];

  # Global/non-user-specific settings
  security.sudo.wheelNeedsPassword = true;

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = true;
      PubkeyAuthentication = true;
    };
  };

  environment.systemPackages = with pkgs; [ bashInteractive ];
  environment.shells = with pkgs; [ bashInteractive ];
  users.defaultUserShell = pkgs.bashInteractive;
}