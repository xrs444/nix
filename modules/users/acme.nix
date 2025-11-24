{ config, lib, pkgs, ... }:

let
  # Provide a default for minimalImage if not defined
  minimalImage = if config ? minimalImage then config.minimalImage else false;
in
lib.mkIf (!minimalImage) {
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