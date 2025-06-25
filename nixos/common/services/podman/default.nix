{
  config,
  hostname,
  lib,
  pkgs,
  ...
}:
let
  installOn = [];
in
lib.mkIf (lib.elem "${hostname}" installOn) {

  virtualisation.containers.enable = true;
  virtualisation = {
    podman = {
      enable = true;
      dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true;
    };
  };
}
