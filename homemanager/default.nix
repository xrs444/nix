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
      inputs.catppuccin.homeModules.catppuccin
      ./common/shell
    ]
    ++ lib.optional (builtins.isString desktop) ./common/desktop
    ++ lib.optional (builtins.pathExists (
      ./. + "/common/users/${username}"
    )) ./common/users/${username};

  # Enable Catppuccin theme globally
  catppuccin = {
    enable = true;
    flavor = "mocha";
  };

  # Enable delta to satisfy catppuccin but disable it
  programs.delta = {
    enable = false;
  };

  home = {
    inherit username stateVersion;
    homeDirectory = lib.mkForce (
      if pkgs.stdenv.isDarwin
      then "/Users/${username}"
      else "/home/${username}"
    );
  };

}
