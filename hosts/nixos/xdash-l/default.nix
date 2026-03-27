# Summary: Minimal NixOS kiosk for xdash-l - WiFi + web display only
{
  pkgs,
  hostname,
  inputs,
  ...
}:

{
  # xdash-l-specific package overrides for minimal kiosk
  # Disable introspection for packages that fail with Python 3.13 distutils
  # This is safe for xdash-l since it's a minimal kiosk with no need for GIR files
  nixpkgs.overlays = [
    (final: prev: {
      # Fix gtk4 distutils error by disabling introspection
      gtk4 = prev.gtk4.overrideAttrs (oldAttrs: {
        outputs = builtins.filter (x: x != "devdoc") oldAttrs.outputs;
        mesonFlags = (oldAttrs.mesonFlags or []) ++ [
          "-Dintrospection=disabled"
          "-Ddocumentation=false"
        ];
      });

      # Fix libadwaita distutils error by disabling introspection
      libadwaita = prev.libadwaita.overrideAttrs (oldAttrs: {
        mesonFlags = (oldAttrs.mesonFlags or []) ++ [
          "-Dintrospection=disabled"
          "-Ddocumentation=false"
        ];
      });

      # Fix gst-plugins-bad distutils error by disabling introspection
      gst_all_1 = prev.gst_all_1.overrideScope (gself: gsuper: {
        gst-plugins-bad = gsuper.gst-plugins-bad.overrideAttrs (oldAttrs: {
          mesonFlags = (oldAttrs.mesonFlags or []) ++ [
            "-Dintrospection=disabled"
            "-Ddoc=disabled"
          ];
        });
      });

      # Fix gjs distutils error by disabling introspection
      gjs = prev.gjs.overrideAttrs (oldAttrs: {
        mesonFlags = (oldAttrs.mesonFlags or []) ++ [
          "-Dintrospection=disabled"
          "-Ddoc=disabled"
        ];
      });
    })
  ];

  imports = [
    ../../base-nixos.nix
    ../common/default.nix
    ../common/hardware-intel.nix
    inputs.nixos-hardware.nixosModules.microsoft-surface-pro-intel
    ../common/boot.nix
    ./hardware-configuration.nix
    ./network.nix
    inputs.sops-nix.nixosModules.sops
    ../../common
  ];

  networking.hostName = hostname;

  boot.supportedFilesystems = [ "vfat" "ext4" ];

  # Minimal kiosk user
  users.users.kiosk = {
    isNormalUser = true;
    description = "Kiosk Display User";
    extraGroups = [ "video" "networkmanager" ];
  };

  # Minimal packages - only what's needed for WiFi + web display
  environment.systemPackages = with pkgs; [
    # Lightweight browser for kiosk (chromium with minimal X11 - no Wayland overhead)
    chromium
  ];

  # Enable minimal graphics, disable audio (not needed for kiosk)
  hardware.graphics.enable = true;
  services.pulseaudio.enable = false;
  services.pipewire.enable = false;
  # Explicitly disable wireplumber (should be disabled with pipewire but isn't)
  services.pipewire.wireplumber.enable = false;

  # Disable desktop services that aren't needed for kiosk
  services.udisks2.enable = false;
  services.accounts-daemon.enable = false;
  services.geoclue2.enable = false;
  services.gnome.at-spi2-core.enable = false;
  xdg.portal.enable = false;

  # Minimal X11 server without desktop environment
  services.xserver = {
    enable = true;
    # No display manager - auto-login to X
    displayManager.startx.enable = true;
    # Minimal window manager just to run fullscreen browser
    windowManager.dwm.enable = true;
  };

  # Auto-login and start kiosk
  services.getty.autologinUser = "kiosk";

  # Auto-start X and browser on login
  environment.loginShellInit = ''
    if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
      exec startx
    fi
  '';

  # Minimal .xinitrc for kiosk user
  environment.etc."X11/xinit/xinitrc".text = ''
    #!/bin/sh
    # Start chromium in kiosk mode (no Wayland, just X11)
    while true; do
      ${pkgs.chromium}/bin/chromium \
        --kiosk \
        --no-first-run \
        --disable-features=TranslateUI \
        --disable-infobars \
        --noerrdialogs \
        --disable-session-crashed-bubble \
        https://hass.xrs444.net
      sleep 5
    done
  '';

  nixpkgs.config.allowUnfree = true;
}
