{ config, pkgs, ... }:

{
  services.xserver.enable = true;
  # Modern display manager and desktop manager options
  services.displayManager.gdm.enable = true;
  services.displayManager.gdm.wayland = true;
  services.desktopManager.gnome.enable = true;

  programs = {
    firefox = {
      enable = true;
      package = pkgs.firefox-esr;
    };
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
  };

  environment.gnome.excludePackages = with pkgs; [
    gnome-calculator
    simple-scan
    cheese
    gnome-music
    epiphany
    geary
    evince
    gnome-characters
    totem
    tali
    iagno
    hitori
    atomix
    yelp
    gnome-maps
    gnome-weather
    gnome-contacts
    gnome-photos
    gnome-tour
  ];

  environment.systemPackages = with pkgs; [
    gnome-remote-desktop
    google-chrome
  ];

  services.gnome.gnome-remote-desktop.enable = true;
  networking.firewall.allowedTCPPorts = [ 3389 ];
  networking.firewall.allowedUDPPorts = [ 3389 ];

}
