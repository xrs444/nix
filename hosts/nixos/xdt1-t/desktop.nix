{ lib, pkgs, ... }:
let
  # Base session script — all per-mode wrappers exec into this.
  # Kept as a named derivation so mode wrappers can reference it by store path.
  niriSessionFixed = pkgs.writeShellScriptBin "niri-session-fixed" ''
    systemctl --user import-environment \
      DISPLAY \
      WAYLAND_DISPLAY \
      XDG_CURRENT_DESKTOP \
      XDG_SESSION_TYPE \
      NIXOS_OZONE_WL \
      WOLF_MODE

    ${pkgs.dbus}/bin/dbus-update-activation-environment --systemd \
      DISPLAY \
      WAYLAND_DISPLAY \
      XDG_CURRENT_DESKTOP \
      XDG_SESSION_TYPE \
      NIXOS_OZONE_WL \
      WOLF_MODE

    exec ${pkgs.niri}/bin/niri-session
  '';

  # Produces a package with:
  #   bin/niri-session-<name>          — sets WOLF_MODE, updates active-mode symlink, execs niri-session-fixed
  #   share/wayland-sessions/niri-<name>.desktop — tuigreet session entry
  mkModeSession =
    {
      name,
      label,
      wolfMode,
    }:
    let
      kdlName = if wolfMode == "" then "base" else wolfMode;
      script = pkgs.writeShellScriptBin "niri-session-${name}" ''
        export WOLF_MODE="${wolfMode}"
        kdl="$HOME/.config/niri/modes/${kdlName}.kdl"
        if [ -f "$kdl" ]; then
          ln -sfn "$kdl" "$HOME/.config/niri/active-mode.kdl"
        fi
        exec ${niriSessionFixed}/bin/niri-session-fixed
      '';
      desktop = pkgs.writeTextFile {
        name = "niri-${name}.desktop";
        destination = "/share/wayland-sessions/niri-${name}.desktop";
        text = ''
          [Desktop Entry]
          Name=${label}
          Comment=Niri scrollable-tiling compositor — ${label}
          Exec=${script}/bin/niri-session-${name}
          Type=Application
        '';
      };
    in
    pkgs.symlinkJoin {
      name = "niri-session-${name}-pkg";
      paths = [
        script
        desktop
      ];
    };

in
{
  # Niri - Scrollable-tiling Wayland compositor
  programs.niri.enable = true;

  # Display manager — session picker shows all registered wayland-sessions .desktop files
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd ${niriSessionFixed}/bin/niri-session-fixed";
        user = "greeter";
      };
    };
  };

  environment.systemPackages =
    with pkgs;
    [
      niriSessionFixed
      (mkModeSession {
        name = "base";
        label = "Niri";
        wolfMode = "";
      })
      (mkModeSession {
        name = "obs";
        label = "Niri (OBS)";
        wolfMode = "obs";
      })
      (mkModeSession {
        name = "llm";
        label = "Niri (LLM)";
        wolfMode = "llm";
      })

      # Desktop shell (not yet in nixos-25.11 — pull from unstable)
      pkgs.unstable.noctalia-shell

      # Essential Wayland desktop components
      fuzzel # App launcher
      mako # Notification daemon
      grim # Screenshot
      slurp # Area selection
      wl-clipboard

      # Terminal
      foot

      # File manager
      thunar

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
