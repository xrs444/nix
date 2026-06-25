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
      USER \
      WOLF_MODE

    ${pkgs.dbus}/bin/dbus-update-activation-environment --systemd \
      DISPLAY \
      WAYLAND_DISPLAY \
      XDG_CURRENT_DESKTOP \
      XDG_SESSION_TYPE \
      NIXOS_OZONE_WL \
      USER \
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
          Exec=niri-session-${name}
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

  niriBase = mkModeSession { name = "base"; label = "Niri"; wolfMode = ""; };
  niriObs  = mkModeSession { name = "obs";  label = "Niri (OBS)"; wolfMode = "obs"; };
  niriLlm  = mkModeSession { name = "llm";  label = "Niri (LLM)"; wolfMode = "llm"; };

in
{
  # Niri - Scrollable-tiling Wayland compositor
  programs.niri.enable = true;

  # Install session .desktop files via environment.etc so they land at a stable path
  # regardless of pathsToLink behaviour in the current nixpkgs niri module.
  environment.etc = {
    "greetd/sessions/niri-base.desktop".source = "${niriBase}/share/wayland-sessions/niri-base.desktop";
    "greetd/sessions/niri-obs.desktop".source  = "${niriObs}/share/wayland-sessions/niri-obs.desktop";
    "greetd/sessions/niri-llm.desktop".source  = "${niriLlm}/share/wayland-sessions/niri-llm.desktop";
  };

  # Display manager — session picker reads /etc/greetd/sessions/ (managed above)
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --sessions /etc/greetd/sessions";
        user = "greeter";
      };
    };
  };

  environment.systemPackages =
    with pkgs;
    [
      niriSessionFixed
      niriBase
      niriObs
      niriLlm

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

      # Image viewer
      imv

      # Gaming utilities
      mangohud
      gamemode

      # RGB lighting control
      openrgb
    ];

  # Enable polkit for privilege escalation prompts
  security.polkit.enable = true;

  # GVfs enables thunar to automount USB drives and removable media
  services.gvfs.enable = true;

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

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  # Use GTK portal instead of GNOME portal (avoids pulling in gjs/ostree/flatpak)
  xdg.portal.extraPortals = lib.mkForce [ pkgs.xdg-desktop-portal-gtk ];

  # OpenRGB server — starts at boot, applies the color profile before the login screen
  services.hardware.openrgb = {
    enable = true;
    motherboard = "amd";  # B850M AORUS ELITE WIFI6E ICE
  };

  systemd.services.openrgb.serviceConfig = {
    # Copy profile into the state dir on each start so git changes propagate
    ExecStartPre = "${pkgs.coreutils}/bin/cp -f ${./openrgb/xrs444.orp} /var/lib/OpenRGB/xrs444.orp";
    # Use state dir as config dir and load the profile at startup
    ExecStart = lib.mkForce "${pkgs.openrgb}/bin/openrgb --server --server-port 6742 --config /var/lib/OpenRGB --profile xrs444";
  };
}
