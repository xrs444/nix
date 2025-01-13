{ pkgs, ...}:
{
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