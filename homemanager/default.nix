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
      # inputs.catppuccin.homeManagerModules.catppuccin
      ./common/shell
    ]
    ++ lib.optional (builtins.isString desktop) ./common/desktop
    ++ lib.optional (builtins.pathExists (
      ./. + "/common/users/${username}"
    )) ./common/users/${username};

  home = {
    inherit username;
    stateVersion = stateVersion or "24.05";
    homeDirectory = lib.mkForce (
      if pkgs.stdenv.isDarwin
      then "/Users/${username}"
      else "/home/${username}"
    );
  };

}
