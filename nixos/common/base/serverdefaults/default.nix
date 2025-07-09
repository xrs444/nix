{
  config,
  hostname,
  isInstall,
  isWorkstation,
  inputs,
  lib,
  modulesPath,
  outputs,
  pkgs,
  platform,
  stateVersion,
  username,
  ...
}:
let
  installOn = [ "xsvr1" "xsvr2" "xsvr3" "xts1" "xts2" ];
in
lib.mkIf (lib.elem hostname installOn) {

  systemd.sleep.extraConfig = ''
    AllowSuspend=no
    AllowHibernation=no
    AllowHybridSleep=no
    AllowSuspendThenHibernate=no
  '';
  systemd.targets.hibernate.enable = false;
  systemd.targets.hybrid-sleep.enable = false;

  boot.kernel.sysctl."vm.page-cluster" = 1;
  zramSwap = {
    algorithm = "lz4";
    enable = true;
  };

  environment = {
    systemPackages =
      with pkgs;
      [
        tcpdump
      ];
  };
}