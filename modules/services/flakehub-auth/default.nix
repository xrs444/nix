# Summary: FlakeHub authentication configuration using sops-managed token
{ config, lib, ... }:
let
  cfg = config.services.flakehub-auth;
in
{
  options.services.flakehub-auth = {
    enable = lib.mkEnableOption "FlakeHub authentication";
  };

  config = lib.mkIf cfg.enable {
    # Deploy the FlakeHub token secret
    sops.secrets.flakehub_token = {
      sopsFile = ../../../secrets/flakehub-token.yaml;
      key = "flakehub_token";
      owner = "root";
      group = "root";
      mode = "0400";
    };

    # Create netrc file using sops template
    sops.templates."nix-netrc" = {
      content = ''
        machine api.flakehub.com login flakehub password ${config.sops.placeholder.flakehub_token}
        machine flakehub.com login flakehub password ${config.sops.placeholder.flakehub_token}
        machine cache.flakehub.com login flakehub password ${config.sops.placeholder.flakehub_token}
      '';
      owner = "root";
      group = "root";
      mode = "0400";
    };

    # Link the template to /etc/nix/netrc
    environment.etc."nix/netrc".source = config.sops.templates."nix-netrc".path;

    # Set the NETRC environment variable for nix-daemon
    systemd.services.nix-daemon.environment.NETRC = "/etc/nix/netrc";
  };
}
