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
{
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  hardware.enableRedistributableFirmware = true;

  fileSystems."/".options = [ "noatime" "nodiratime" "discard" ]; 

  time.timeZone = "America/Phoenix";

  console.keyMap = "us";
  services.xserver.xkb.layout = "us";

  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = "en_US.UTF-8";
      LC_IDENTIFICATION = "en_US.UTF-8";
      LC_MEASUREMENT = "en_US.UTF-8";
      LC_MONETARY = "en_US.UTF-8";
      LC_NAME = "en_US.UTF-8";
      LC_NUMERIC = "en_US.UTF-8";
      LC_PAPER = "en_US.UTF-8";
      LC_TELEPHONE = "en_US.UTF-8";
      LC_TIME = "en_US.UTF-8";
    };
  };

  networking = {
    hostName = hostname;
  };

  environment.systemPackages = with pkgs; [
    git
    nix-output-monitor
    pciutils
    nvd
    nvme-cli
    rsync
    smartmontools
    sops
  ]
  ++ lib.optionals isInstall (
    lib.optionals (platform == "x86_64-linux" || platform == "i686-linux") [
      inputs.determinate.packages.${platform}.default
      inputs.fh.packages.${platform}.default
      inputs.nixos-needsreboot.packages.${platform}.default
    ]
    ++ lib.optionals (platform == "aarch64-linux") [
    ]
  );

  services = {
    chrony = {
      enable = true;
      servers = [ "time.xrs444.net" ];
      extraConfig = ''
        makestep 1.0 3
      '';
    };
    fwupd.enable = isInstall;
    journald.extraConfig = "SystemMaxUse=250M";
  };

  security = {
    polkit.enable = true;
    rtkit.enable = true;
  };

  programs.nh = {
    enable = true;
    package = pkgs.unstable.nh;
    flake = "/home/thomas-local/nixos-config";
    clean = {
      enable = true;
      extraArgs = "--keep-since 10d --keep 3";
    };
    nixos.label = lib.mkIf isInstall "-";
    inherit stateVersion;
  };

  # Create dirs for home-manager
  systemd.tmpfiles.rules = [ "d /nix/var/nix/profiles/per-user/${username} 0755 ${username} root" ];
}
