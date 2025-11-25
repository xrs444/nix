{ config,
  desktop ? null,
  lib ? null,
  pkgs ? null,
  outputs,
  stateVersion,
  username,
  inputs,
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
    ++ lib.optional (builtins.pathExists (./. + "/common/users/${username}")) ./common/users/${username}
    ++ lib.optional (builtins.pathExists (./. + "/users/${username}")) ./users/${username};

  home = {
    inherit username;
    stateVersion = if stateVersion != null then stateVersion else "24.05";
    homeDirectory = lib.mkForce (
      if pkgs.stdenv.isDarwin
      then "/Users/${username}"
      else "/home/${username}"
    );
  };

}
