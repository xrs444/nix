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
    defaultLocale = "en_US.utf8";
    extraLocaleSettings = {
      LC_ADDRESS = "en_US.utf8";
      LC_IDENTIFICATION = "en_US.utf8";
      LC_MEASUREMENT = "en_US.utf8";
      LC_MONETARY = "en_US.utf8";
      LC_NAME = "en_US.utf8";
      LC_NUMERIC = "en_US.utf8";
      LC_PAPER = "en_US.utf8";
      LC_TELEPHONE = "en_US.utf8";
      LC_TIME = "en_US.utf8";
    };
  };


  networking = {
    hostName = hostname;
    };
  
  environment.systemPackages = with pkgs; [
    bat
    binutils
    curl
    dig
    git
    killall
    nfs-utils
    rsync
    traceroute
    tree
    wget
    nix-output-monitor
    nixfmt-rfc-style
    usbutils
      ]
    ++ lib.optionals isInstall [
      inputs.determinate.packages.${platform}.default
      inputs.fh.packages.${platform}.default
      inputs.nixos-needsreboot.packages.${platform}.default
      nvd
      nvme-cli
      smartmontools
      sops
    ];

    services = {

      chrony = {
        enable = true;
        servers = [ "time.xrs444.net"];
        extraConfig = ''
          rtcsync
          makestep 1.0 3
        '';
      };
      
      fwupd.enable = isInstall;
      journald.extraConfig = "SystemMaxUse=250M";
      flatpak.enable = true;
    };
  
    security = {
      polkit.enable = true;
      rtkit.enable = true;
    };
  
    users.mutableUsers = true;
  
  programs.nh = {
    enable = true;
    package = pkgs.unstable.nh;
    flake = "/home/thomas-local/nixos-config";
    clean = {
      enable = true;
      extraArgs = "--keep-since 10d --keep 3";
    };
  };


    # Create dirs for home-manager
    systemd.tmpfiles.rules = [ "d /nix/var/nix/profiles/per-user/${username} 0755 ${username} root" ];
  }
  