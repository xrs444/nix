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
boot.kernelPackages = pkgs.linuxPackages_latest;
boot.kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;
  
networking.hostName = "srv-t1"; # Define your hostname.
networking.hostId = "8fa5e746";
  # Pick only one of the below networking options.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
networking.networkmanager.enable = true;  # Easiest to use and most distros use this by default.

  # Set your time zone.
time.timeZone = "America/Phoenix";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkb.options in tty.
  # };

  # Enable the X11 windowing system.
  # services.xserver.enable = true;

  # Configure keymap in X11
  # services.xserver.xkb.layout = "us";
  # services.xserver.xkb.options = "eurosign:e,caps:escape";

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  # hardware.pulseaudio.enable = true;
  # OR
  # services.pipewire = {
  #   enable = true;
  #   pulse.enable = true;
  # };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
 users.users.thomas-local = {
   isNormalUser = true;
   extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
   packages = with pkgs;
  #     tree
   ];
 };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
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


# Open ports in the firewall.
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

#Enable Hypervisor

virtualisation.libvirtd.enable = true;

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
