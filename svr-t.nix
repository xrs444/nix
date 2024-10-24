# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Use the GRUB 2 boot loader.
boot.loader.grub.enable = true;
  # boot.loader.grub.efiSupport = true;
  # boot.loader.grub.efiInstallAsRemovable = true;
  # boot.loader.efi.efiSysMountPoint = "/boot/efi";
  # Define on which hard drive you want to install Grub.
boot.loader.grub.device = "/dev/sda"; # or "nodev" for efi only
boot.kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;
boot.kernelModules = [ "kvm-amd" "kvm-intel" ];
virtualisation.libvirtd.enable = true;

# Localization
  time.timeZone = "America/Phoenix";
  i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkb.options in tty.
  # };

# Networking
  networking.hostName = "srv-t1"; # Define your hostname.
  networking.hostId = "8fa5e746";
  networking.networkmanager.enable = true;  # Easiest to use and most distros use this by default.

# Firewall
  networking.firewall.allowedTCPPorts = [
    6443 # k3s
    2379 # k3s - etcd clients
    2380 # k3s - etcd peers
    80 # http
    443 # https
    9090 # cockpit
  ];

  networking.firewall.allowedUDPPorts = [ 
    8472 # k3s - Flannel
  ];


# Users
 users.users.thomas-local = {
   isNormalUser = true;
   extraGroups = [ "wheel" "libvirtd" ];.
   packages = with pkgs;
  #     tree
   ];
 };

# System Packages
  environment.systemPackages = with pkgs; [
    cockpit 
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

#Services
  services.openssh.enable = true; #SSH
  services.nfs.server.enable = true; #NFS

  services.k3s = {
    enable = true;
    role = "server";
    token = "<randomized common secret>";
    clusterInit = true;
  };

  services.cockpit = {
    enable = true;
    port = 9090;
    settings = {
      WebService = {
        AllowUnencrypted = true;
      };
    };
  };






  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "24.05"; # Did you read the comment?

}
