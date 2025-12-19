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

  services.displayManager.gdm = {
    enable = true;
    wayland = true;
  };

  services.desktopManager.gnome = {
    enable = true;
  };

  # Exclude GNOME packages that depend on gst-plugins-rs (causes OOM during build)
  environment.gnome.excludePackages = with pkgs; [
    gnome-contacts # Depends on gst-plugins-rs
    gnome-music # Depends on gst-plugins-rs
    cheese # Depends on gst-plugins-rs
    totem # Video player, depends on gst-plugins-rs
    epiphany # Web browser
    geary # Email client
    gnome-photos # Photo viewer
    snapshot # Camera app
    showtime # Media player
  ];

  # Explicitly install only essential GNOME apps to avoid gst-plugins-rs build issues
  environment.systemPackages = with pkgs; [
    nautilus # File manager (moved to top-level)
    gnome-terminal # Terminal
    gnome-system-monitor # System monitor
    gnome-disk-utility # Disk utility
    gnome-settings-daemon # Settings (moved to top-level)
    gnome-control-center # Settings UI (moved to top-level)
    file-roller # Archive manager (moved to top-level)
    eog # Image viewer (moved to top-level)
    # Add other GNOME apps here as needed, avoiding those with gst-plugins-rs deps
  ];

  services.gnome.gnome-remote-desktop.enable = true;
  networking.firewall.allowedTCPPorts = [ 3389 ];
  networking.firewall.allowedUDPPorts = [ 3389 ];

}
