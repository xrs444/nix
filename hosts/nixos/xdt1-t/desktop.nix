{ lib, pkgs, ... }:
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

  environment.systemPackages = with pkgs; [
    # Custom niri session wrapper
    (writeShellScriptBin "niri-session-fixed" ''
      systemctl --user import-environment \
        DISPLAY \
        WAYLAND_DISPLAY \
        XDG_CURRENT_DESKTOP \
        XDG_SESSION_TYPE \
        NIXOS_OZONE_WL

      ${dbus}/bin/dbus-update-activation-environment --systemd \
        DISPLAY \
        WAYLAND_DISPLAY \
        XDG_CURRENT_DESKTOP \
        XDG_SESSION_TYPE \
        NIXOS_OZONE_WL

      exec ${niri}/bin/niri-session
    '')

    # Desktop shell (not yet in nixos-25.11 — pull from unstable)
    pkgs.unstable.noctalia-shell

    # Essential Wayland desktop components
    fuzzel      # App launcher
    mako        # Notification daemon
    grim        # Screenshot
    slurp       # Area selection
    wl-clipboard

    # Terminal
    foot

    # File manager
    xfce.thunar

    # Audio / network
    pavucontrol
    networkmanagerapplet

    # Polkit agent
    polkit_gnome

    # Image viewer / remote desktop
    imv
    rustdesk-flutter

    # Gaming utilities
    mangohud
    gamemode

    # RGB lighting control
    openrgb
  ];

  # Enable polkit for privilege escalation prompts
  security.polkit.enable = true;

  # GameMode daemon — lets games request performance governor
  programs.gamemode.enable = true;

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

  # Autostart noctalia-shell after niri session comes up
  systemd.user.services.noctalia = {
    description = "Noctalia shell";
    wantedBy = [ "graphical-session.target" ];
    wants = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.unstable.noctalia-shell}/bin/noctalia-shell";
      Restart = "on-failure";
      RestartSec = 2;
    };
  };

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  # Use GTK portal instead of GNOME portal (avoids pulling in gjs/ostree/flatpak)
  xdg.portal.extraPortals = lib.mkForce [ pkgs.xdg-desktop-portal-gtk ];
}
