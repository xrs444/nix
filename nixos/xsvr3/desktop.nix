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
  environment.gnome.excludePackages = (with pkgs; [
    epiphany # web browsere
    gnome-calculator
    yelp # help viewer
    simple-scan
    ]);
}
