{ pkgs, ...}:
{
  environmnet.systemPackages = with pkgs; [
    zfs
  ];
  services.zfs = {
    autoScrub.enable = true;
  };
}

