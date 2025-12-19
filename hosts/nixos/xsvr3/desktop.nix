{ config, pkgs, ... }:

{
  services = {
    xserver = {
      enable = true;
      xkb = {
        layout = "us";
        variant = "";
      };
    };
    libinput.enable = true;
  };

  programs = {
    firefox.enable = true;
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
  };

  # Use LXQt instead of GNOME to avoid heavy build dependencies
  services.displayManager.sddm.enable = true;
  services.desktopManager.lxqt.enable = true;

  # Essential applications
  environment.systemPackages = with pkgs; [
    # File manager and utilities (provided by LXQt)
    # Additional useful applications
    firefox
    gnome-system-monitor # Keep for monitoring
    file-roller # Archive manager

    # Remote desktop
    xrdp
  ];

  # Enable xrdp for remote desktop access
  services.xrdp = {
    enable = true;
    defaultWindowManager = "startlxqt";
    openFirewall = true;
  };

  networking.firewall.allowedTCPPorts = [ 3389 ];
  networking.firewall.allowedUDPPorts = [ 3389 ];

}
