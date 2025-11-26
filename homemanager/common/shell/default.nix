{ pkgs, self, ... }:
let
  theme = import "${self}/lib/theme" { inherit pkgs; };
in
{
  # No imports here; user-specific modules are imported in user configs

  programs = {
    git.enable = true;
    home-manager.enable = true;
  };

  home.packages = with pkgs; [
    age
    sops
  ];
}
