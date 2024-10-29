{
  config,
  inputs,
  pkgs,
  username,
  ...
}:
{

  imports = [
    inputs.nixos-hardware.nixosModules.common-pc
    inputs.nixos-hardware.nixosModules.common-cpu-amd
    inputs.nixos-hardware.nixosModules.common-pc-ssd

    ./hardware-configuration.nix
    ./disks.nix

  ];


  boot = {  
    loader.grub.enable = true;
    loader.grub.efiSupport = true;
  # loader.grub.efiInstallAsRemovable = true;
    loader.efi.efiSysMountPoint = "/boot/efi";
    loader.grub.device = "nodev"; # or "nodev" for efi only
    kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;
    kernelModules = [ 
      "kvm-amd"
      ];
    virtualisation.libvirtd.enable = true;
    swraid = {
      enable = true;
      mdadmConf = "PROGRAM=true";
    };
}
{

  services = {
      openssh = {
        enable = true;
        # Don't open the firewall on for SSH on laptops; Tailscale will handle it.
#        openFirewall = !isLaptop;
        settings = {
          PasswordAuthentication = true;
          PermitRootLogin = "no";
        };
      };
#      sshguard = {
#        enable = true;
#        whitelist = [
#         "192.168.2.0/24"
#          "62.31.16.154"
#          "80.209.186.64/28"
#        ];
#      };
  };
}



  nixpkgs = {
    # You can add overlays here
    overlays = [
      # If you want to use overlays exported from other flakes:
      # neovim-nightly-overlay.overlays.default

      # Or define it inline, for example:
      # (final: prev: {
      #   hi = final.hello.overrideAttrs (oldAttrs: {
      #     patches = [ ./change-hello-to-hi.patch ];
      #   });
      # })
    ];
    # Configure your nixpkgs instance
    config = {
      # Disable if you don't want unfree packages
      allowUnfree = true;
    };
  };

  nix = let
    flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
  in {
    settings = {
      # Enable flakes and new 'nix' command
      experimental-features = "nix-command flakes";
      # Opinionated: disable global registry
      flake-registry = "";
      # Workaround for https://github.com/NixOS/nix/issues/9574
      nix-path = config.nix.nixPath;
    };
    # Opinionated: disable channels
    channel.enable = false;

    # Opinionated: make flake registry and nix path match flake inputs
    registry = lib.mapAttrs (_: flake: {inherit flake;}) flakeInputs;
    nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
  };

  # Localization

  time.timeZone = "America/Phoenix";
  i18n.defaultLocale = "en_US.UTF-8";

  # Networks 
  networking.hostName = "srv-t1"; # Hostname
  networking.hostId = "8fa5e746"; # ZFS uses this
  networking.networkmanager.enable = true;
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


  # TODO: Configure your system-wide user settings (groups, etc), add more users as needed.
  users.users = {
    # FIXME: Replace with your username
    thomas-local = {
      # If you do, you can skip setting a root password by passing '--no-root-passwd' to nixos-install.
      # Be sure to change it (using passwd) after rebooting!
      initialPassword = "SoItBegins";
      isNormalUser = true;
      openssh.authorizedKeys.keys = [
        # TODO: Add your SSH public key(s) here, if you plan on using SSH to connect
      ];
      extraGroups = ["wheel" "libvirtd"];
    };
  };


  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "24.05";
}
