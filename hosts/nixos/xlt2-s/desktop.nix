{ pkgs, ... }:
{
  # Standard GNOME desktop.
  services.xserver.enable = true;
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };
  services.libinput.enable = true;

  services.desktopManager.gnome.enable = true;
  services.displayManager.gdm.enable = true;

  # epiphany/evolution-data-server/yelp all pull in webkitgtk, which isn't
  # on the binary cache and OOM-killed mid-compile (exit 137, ~89% through)
  # on the xsvr1 remote builder. Excluding them avoids building webkitgtk
  # at all. Samantha uses Chrome for browsing; core GNOME (Files, Settings,
  # etc.) is unaffected.
  environment.gnome.excludePackages = with pkgs; [
    epiphany
    evolution-data-server
    yelp
    # gnome-maps pulls libshumate, whose meson test suite times out on
    # 10/16 tests (~715s each) under concurrent builder load — 0 genuine
    # failures, and libshumate-1.6.3 isn't on cache.nixos.org, so it's a
    # full from-source build every time. xlt2-s is the only GNOME host in
    # the fleet (others run niri), so this removes libshumate entirely.
    gnome-maps
  ];

  environment.systemPackages = with pkgs; [
    file-roller # Archive manager
    gparted # Partition editor
    prismlauncher # Minecraft launcher
    solaar # Logitech Unifying/Bolt receiver manager
  ];

  # solaar's own `udev` output (aliased as logitech-udev-rules) grants
  # unprivileged access to the Logitech receiver — without it Solaar can only
  # read device state as root. Package comment explicitly recommends this
  # alias over wiring the derivation's `udev` output directly.
  services.udev.packages = [ pkgs.logitech-udev-rules ];
}
