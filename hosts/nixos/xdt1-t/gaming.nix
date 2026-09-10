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

  # System-wide gamescope, for wrapping games via Steam launch options
  # (gamescope -W 3840 -H 2160 -f -- %command%). Not covered by the
  # `p.gamescope` in Lutris's extraPkgs below — that copy is only on PATH
  # inside Lutris's own FHS sandbox, not for Steam-launched games.
  #
  # capSysNice is deliberately left off (default false). With it on, the
  # setcap wrapper's file capabilities make Steam's bwrap/pressure-vessel FHS
  # sandbox refuse the process ("bwrap: Unexpected capabilities but not
  # setuid, old file caps config?"), which gamescope surfaces as "failed to
  # inherit capabilities: Operation not permitted" and exits immediately —
  # Steam shows the Play button bounce from loading back to Ready with no
  # window ever appearing. This is a known, still-open upstream nixpkgs/bwrap
  # interaction (nixpkgs#351516) with no real fix, only this workaround.
  # Without capSysNice, gamescope just logs "No CAP_SYS_NICE, falling back to
  # regular-priority compute and threads" and launches normally.
  programs.gamescope.enable = true;

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
