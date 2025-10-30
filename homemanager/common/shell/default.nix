{ pkgs, self, ... }:
let
  theme = import "${self}/lib/theme" { inherit pkgs; };
in
{
  imports = [
 #   ./atuin.nix
    ./git.nix
    ./starship.nix
    ./tmux.nix
  ];

  programs = {
    git.enable = true;
    home-manager.enable = true;
  };

  home.packages = with pkgs; [
    age
    sops
  ];
}
