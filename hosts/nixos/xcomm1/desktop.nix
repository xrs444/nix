{ pkgs, lib, ... }:

{
  # Niri - Scrollable-tiling Wayland compositor
  programs.niri.enable = true;

  # Display manager for login
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd niri-session-fixed";
        user = "greeter";
      };
    };
  };

  # Wayland-native utilities and custom niri session wrapper
  environment.systemPackages = with pkgs; [
    # Custom niri session wrapper to fix the import-environment deprecation warning
    (writeShellScriptBin "niri-session-fixed" ''
      # Import only the necessary environment variables instead of all
      systemctl --user import-environment \
        DISPLAY \
        WAYLAND_DISPLAY \
        XDG_CURRENT_DESKTOP \
        XDG_SESSION_TYPE \
        NIXOS_OZONE_WL

      # Update dbus activation environment
      ${dbus}/bin/dbus-update-activation-environment --systemd \
        DISPLAY \
        WAYLAND_DISPLAY \
        XDG_CURRENT_DESKTOP \
        XDG_SESSION_TYPE \
        NIXOS_OZONE_WL

      # Start niri
      exec ${niri}/bin/niri-session
    '')

    # Essential Wayland desktop components
    fuzzel            # App launcher (Super+D or configure in Niri)
    waybar            # Status bar
    # Browsers
    google-chrome

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

    # Image viewer
    imv               # Wayland image viewer

    # Remote desktop
    rustdesk-flutter  # Cross-platform remote desktop client
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
