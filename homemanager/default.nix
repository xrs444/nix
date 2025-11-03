{
  config,
  desktop,
  lib,
  outputs,
  stateVersion,
  username,
  inputs,
  pkgs,
  ...
}:
{
  # Only import desktop configuration if the host is desktop enabled
  # Only import user specific configuration if they have bespoke settings
  imports =
    [
      ./common/shell
    ]
    ++ lib.optional (builtins.isString desktop) ./common/desktop
    ++ lib.optional (builtins.pathExists (
      ./. + "/common/users/${username}"
    )) ./common/users/${username};

  home = {
    inherit username stateVersion;
    homeDirectory = lib.mkForce (
      if pkgs.stdenv.isDarwin
      then "/Users/${username}"
      else "/home/${username}"
    );
  };

  # Remove this entire nixpkgs section when using home-manager.useGlobalPkgs = true
  # nixpkgs configuration is handled at the system level instead
}
