{ pkgs, ...}:
{
  boot.supportedFilesystems = [ "zfs" ];
  environment.systemPackages = with pkgs; [
    zfs
  ];
  services.zfs = {
    autoScrub.enable = true;
  };
}

