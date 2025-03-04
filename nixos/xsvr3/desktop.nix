{ config, pkgs, ... }:

{
  services = {
    xserver = {
      enable = true;
      displayManager.gdm = {
        enable = true;
        wayland = true;
      };
    desktopManager.gnome.enable = true;
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
}
