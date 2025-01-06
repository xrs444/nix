{ pkgs, ...}:
{
  environment.systemPackages = with pkgs; [
    zfs
  ];
  services.zfs = {
    enable = true;
    autoScrub.enable = true;
  };
}

