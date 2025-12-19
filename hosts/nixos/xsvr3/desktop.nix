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
    extraGSettingsOverrides = "";
    extraGSettingsOverridePackages = [ ];
  };

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
