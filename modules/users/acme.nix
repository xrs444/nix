{ config, lib, pkgs, ... }:

{
  users.users.acme = {
    isSystemUser = true;
    group = "acme";
    home = "/var/lib/acme";
    createHome = true;
    shell = pkgs.bash;
    openssh.authorizedKeys.keys = [
      config.sops.secrets."acme/ssh-key".path
    ];
  };

  users.groups.acme = {};

  sops.secrets."acme/ssh-key" = {
    sopsFile = builtins.path { path = ./secrets/acme.yaml; };
    owner = "acme";
    group = "acme";
    mode = "0400";
  };
}