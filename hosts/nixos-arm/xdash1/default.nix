# Summary: Minimal NixOS kiosk for xdash1 - WiFi + web display only
{
  pkgs,
  hostname,
  inputs,
  ...
}:

{
  imports = [
    ../../base-nixos.nix
    ../common/default.nix
    ../../../modules/hardware/OrangePiZero3
    ../common/boot.nix
    ./network.nix
    ../../../modules/sdImage/custom.nix
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
