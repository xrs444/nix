{
  config,
  hostname,
  isWorkstation,
  lib,
  pkgs,
  username,
  ...
}:
let
  # Declare which hosts have zfs enabled.
  installOn = [
    "xsvr1"
    "xsvr2"
  ];

in
lib.mkIf (lib.elem "${hostname}" installOn) {
  boot.supportedFilesystems = [ "zfs" ];
  environment.systemPackages = with pkgs; [
    zfs
  ];
  services.zfs = {
    autoScrub.enable = true;
  };

  services.sanoid = {
  enable = true;
  datasets = {
    "zroot/persist" = {
       hourly = 50;
       daily = 15;
       weekly = 3;
       monthly = 1;
       };
    };
  };
}