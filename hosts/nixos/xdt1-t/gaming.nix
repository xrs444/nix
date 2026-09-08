{ lib, pkgs, ... }:
{
  # common/audio-pipewire.nix disables this fleet-wide (32-bit pipewire was
  # previously not worth the extra build/cache surface on hosts with no use
  # for it). Steam's module wants it on for 32-bit games that talk to ALSA
  # directly rather than through the 64-bit PulseAudio bridge; both set it at
  # the same priority, so without mkForce here eval fails with a conflicting
  # definition error.
  services.pipewire.alsa.support32Bit = lib.mkForce true;

  programs.steam = {
    enable = true;
    protontricks.enable = true;
    # Translates X11 input events to uinput so Steam Input works under niri
    # (Wayland). Relies on hardware.uinput, enabled host-wide for xrs444.nix.
    extest.enable = true;
    extraCompatPackages = [ pkgs.proton-ge-bin ];
  };

  programs.gamemode.enable = true;

  environment.systemPackages = with pkgs; [
    mangohud
    gamemode
    prismlauncher

    # FHS-wrapped; Lutris manages its own downloaded Wine/Proton runners
    # inside the sandbox rather than using a nixpkgs wine build directly.
    (lutris.override {
      extraPkgs = p: [ p.gamemode p.mangohud p.gamescope p.winetricks ];
    })
    winetricks

    # jstest / jscal / fftest — calibrating the SideWinder FFB2's axes and
    # force-feedback effects.
    linuxConsoleTools
  ];

  # Controller udev permissions (8BitDo etc.) beyond what Steam's own rules
  # (pulled in via hardware.steam-hardware, set by the steam module) cover —
  # needed for Lutris and other non-Steam launches.
  services.udev.packages = [ pkgs.game-devices-udev-rules ];
}
