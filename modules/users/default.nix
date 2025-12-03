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
  ]
  ++ lib.optional (!minimalImage) ./builder.nix
  ++ lib.optional (!minimalImage) ./acme.nix;

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
