{
  desktop ? null,
  lib ? null,
  pkgs ? null,
  stateVersion,
  username,
  ...
}:
{
  # Only import desktop configuration if the host is desktop enabled
  # Only import user specific configuration if they have bespoke settings
  imports = [
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
      if pkgs.stdenv.isDarwin then "/Users/${username}" else "/home/${username}"
    );
    # Reverse scroll direction on macOS (disable "Natural" scrolling)
    activation.reverseScrollDirection = lib.mkIf pkgs.stdenv.isDarwin ''
      /usr/bin/defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false
    '';
  };

}
