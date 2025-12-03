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

    displayManager.gdm = {
      enable = true;
      wayland = true;
    };
    desktopManager.gnome.enable = true;
  };

  programs = {
    firefox.enable = true;
    gnome-disks.enable = true;
  };

  environment = {
    systemPackages = with pkgs; [
      gnome-tweaks
      dconf-editor
    ];

    gnome.excludePackages = (
      with pkgs;
      [
        gnome-tour
        cheese # webcam tool
        gnome-music
        epiphany # web browser
        geary # email reader
        gnome-characters
        tali # poker game
        iagno # go game
        hitori # sudoku game
        atomix # puzzle game
      ]
    );
  };
}
