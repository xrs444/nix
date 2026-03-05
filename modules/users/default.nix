{
  config,
  lib,
  pkgs,
  minimalImage,
  ...
}:
{
  imports = [
    ./thomas-local.nix
    ./xrs444.nix
  ]
  ++ lib.optional (!minimalImage) ./builder.nix;

  config = {
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
  };
}
