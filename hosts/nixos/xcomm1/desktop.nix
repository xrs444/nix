{ pkgs, ... }:

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

  # Wayland-native utilities
  environment.systemPackages = with pkgs; [
    # Essential Wayland desktop components
    fuzzel            # App launcher (Super+D or configure in Niri)
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
    pavucontrol       # Audio control
    networkmanagerapplet  # Network manager GUI

    # Polkit agent (for authentication prompts)
    polkit_gnome

    # Media playback
    mpv               # Video player

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

  # Note: Removed gnome-remote-desktop (GNOME-specific)
  # For Wayland remote desktop, consider:
  # - wayvnc (VNC server for wlroots-based compositors)
  # - rustdesk (cross-platform remote desktop)
  # Uncomment if needed:
  # environment.systemPackages = with pkgs; [ wayvnc ];
  # networking.firewall.allowedTCPPorts = [ 5900 ]; # VNC port

}
