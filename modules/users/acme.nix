{ config, lib, pkgs, ... }:

{
  users.users.acme = {
    isSystemUser = true;
    group = "acme";
    home = "/var/lib/acme";
    createHome = true;
    shell = pkgs.bash;
    openssh.authorizedKeys.keys = [
      (builtins.readFile config.sops.secrets."acme/ssh-key".path)
    ];
    # Remove initialPassword if only using SSH keys
  };

  users.groups.acme = {};

  sops.secrets."acme/ssh-key" = {
    sopsFile = ../../../secrets/acme.yaml;
    owner = "acme";
    group = "acme";
    mode = "0400";
  };
}