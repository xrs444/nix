{ config, lib, pkgs, ... }:

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

    # Disable audio - xlabmgmt has no audio hardware
    pipewire.enable = lib.mkForce false;
    pulseaudio.enable = false;
  };

  programs = {
    gnome-disks.enable = true;
  };

  environment = {
    systemPackages = with pkgs; [
      gnome-tweaks
      dconf-editor
      google-chrome
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
