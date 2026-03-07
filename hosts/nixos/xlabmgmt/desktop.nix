{ lib, pkgs, ... }:

{
  # Niri - Scrollable-tiling Wayland compositor
  programs.niri.enable = true;

  # Display manager for login
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd niri-session";
        user = "greeter";
      };
    };
  };

  # Disable audio - xlabmgmt has no audio hardware
  services.pipewire.enable = lib.mkForce false;
  services.pulseaudio.enable = false;

  # Wayland-native utilities
  environment.systemPackages = with pkgs; [
    # Essential Wayland desktop components
    fuzzel            # App launcher
    waybar            # Status bar

    # Browsers
    google-chrome
    firefox

    # Wayland desktop essentials
    mako              # Notification daemon
    grim              # Screenshot tool
    slurp             # Screen area selection
    wl-clipboard      # Clipboard utilities

    # Terminal (Wayland-native)
    foot              # Lightweight Wayland terminal

    # File manager
    xfce.thunar       # Simple GUI file manager

    # System utilities
    networkmanagerapplet  # Network manager GUI
    # Note: Removed pavucontrol (no audio hardware)

    # Polkit agent (for authentication prompts)
    polkit_gnome

    # Disk management (non-GNOME alternative)
    gnome-disk-utility  # Still works without full GNOME

    # Image viewer
    imv               # Wayland image viewer
  ];

  # Enable polkit for authentication
  security.polkit.enable = true;

  # Auto-start polkit agent
  systemd.user.services.polkit-gnome-authentication-agent-1 = {
    description = "polkit-gnome-authentication-agent-1";
    wantedBy = [ "graphical-session.target" ];
    wants = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
      Restart = "on-failure";
      RestartSec = 1;
      TimeoutStopSec = 10;
    };
  };

  programs = {
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
  };
}
