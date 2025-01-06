_: {
  basePackages = with pkgs; [
    zfs
  ];
  services.zfs = {
    autoScrub.enable = true;
  };
}

