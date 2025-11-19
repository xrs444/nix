{ config, lib, pkgs, ... }:

lib.mkIf (!config.minimalImage) {
  users.users.acme = {
    isSystemUser = true;
    group = "acme";
    home = "/var/lib/acme";
    createHome = true;
    shell = pkgs.bash;
    openssh.authorizedKeys.keys = [
      config.sops.secrets."ssh-key".path
    ];
  };

  users.groups.acme = {};

  sops.secrets."ssh-key" = {
    sopsFile = ../../secrets/acme.yaml;
    owner = "acme";
    group = "acme";
    mode = "0400";
  };
}