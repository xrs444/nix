{
    hostname,
    pkgs,
    lib,
    username,
    ...
  }:
  {
  
    networking = {
      hostName = hostname;
    };
  
    environment.systemPackages = (import ./packages.nix { inherit pkgs; }).basePackages;
  
    services = {
      chrony.enable = true;
      journald.extraConfig = "SystemMaxUse=250M";
   #   flatpak.enable = true;
    };
  
    security = {
      polkit.enable = true;
      rtkit.enable = true;
    };
  
    users.mutableUsers = true;
  
    # Create dirs for home-manager
    systemd.tmpfiles.rules = [ "d /nix/var/nix/profiles/per-user/${username} 0755 ${username} root" ];
  }
  