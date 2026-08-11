# Summary: NixOS module for workstation-specific packages, adds custom system packages for desktop environments.
{ pkgs, lib, config, ... }:

{
  options.workstationPackages.enableObs = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Whether to include obs-studio in this workstation's default packages.";
  };

  config.environment.systemPackages =
    with pkgs;
    lib.optionals stdenv.isLinux (
      [
        google-chrome
        beeper
      ]
      ++ lib.optional config.workstationPackages.enableObs obs-studio
    );
}
