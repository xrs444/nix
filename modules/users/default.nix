{
  config,
  lib,
  pkgs,
  minimalImage,
  hostname ? null,
  ...
}:
{
  imports = [
    ./thomas-local.nix
    ./xrs444.nix
    ./deploy.nix
    ../services/kanidm/pam-client.nix
  ]
  ++ lib.optional (!minimalImage) ./builder.nix
  # Samantha's account only exists on her own laptop, not fleet-wide like
  # the admin accounts above.
  ++ lib.optional (hostname == "xlt2-s") ./samantha.nix;

  config = {
    security.sudo.wheelNeedsPassword = true;

    services.openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = false;
        PubkeyAuthentication = true;
      };
    };

    environment.systemPackages = with pkgs; [ bashInteractive ];
    environment.shells = with pkgs; [ bashInteractive ];
    users.defaultUserShell = pkgs.bashInteractive;
  };
}
