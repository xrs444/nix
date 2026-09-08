{ lib, pkgs, ... }:
let
  # Workflow mode (base/OBS/LLM/gaming) is chosen at runtime via the wolf-mode
  # fuzzel menu (Mod+Shift+M, see homemanager/common/desktop/niri/modes/switcher.nix),
  # not at login — greetd only needs a single niri session.
  niriSessionFixed = pkgs.writeShellScriptBin "niri-session-fixed" ''
    systemctl --user import-environment \
      DISPLAY \
      WAYLAND_DISPLAY \
      XDG_CURRENT_DESKTOP \
      XDG_SESSION_TYPE \
      NIXOS_OZONE_WL \
      USER

    ${pkgs.dbus}/bin/dbus-update-activation-environment --systemd \
      DISPLAY \
      WAYLAND_DISPLAY \
      XDG_CURRENT_DESKTOP \
      XDG_SESSION_TYPE \
      NIXOS_OZONE_WL \
      USER

    exec ${pkgs.niri}/bin/niri-session
  '';
in
{
  # Niri - Scrollable-tiling Wayland compositor
  programs.niri.enable = true;

  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd niri-session-fixed";
        user = "greeter";
      };
    };
  };

  environment.systemPackages =
    with pkgs;
    [
      niriSessionFixed

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
      gparted # Partition editor

      # Niri (25.08+) auto-spawns this on demand once it's on PATH, exporting
      # $DISPLAY. Needed for GParted's pkexec+xhost root-elevation to have an
      # X11 display to attach to — without it, GParted's root process has no
      # display at all and exits silently.
      xwayland-satellite

      # Audio / network
      pavucontrol
      networkmanagerapplet

      # Polkit agent
      polkit_gnome

      # Image viewer
      imv

      # Disc ripping for Romm (bin/cue) — redumper does the actual dump,
      # cuetools verifies/post-processes the resulting cue sheets
      redumper
      cuetools

      # DOS game testing/config-building for Romm — run installers (e.g. sound
      # setup) against real files here, then bake the resulting config files
      # into the game's zip, since Romm's own dosbox-pure mount is ephemeral
      dosbox
      bchunk

      # RGB lighting control
      openrgb

      # Active Directory management (Samba AD / Windows AD)
      openrsat
    ];

  # Enable polkit for privilege escalation prompts
  security.polkit.enable = true;

  # GVfs enables thunar to automount USB drives and removable media
  services.gvfs.enable = true;

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
