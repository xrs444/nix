# This file contains only the GitKraken-related configuration split from the original default.nix.
# It is not intended to be used standalone; import it from your main config if needed.
{
  config,
  ...
}:
{
  home.file = {
    "${config.home.homeDirectory}/.gitkraken/themes/catppuccin_mocha.jsonc".text =
      builtins.readFile ./catppuccin-mocha-blue-upstream.json;
  };
  # gitkraken installed via homebrew cask (nixpkgs 25.11 gitkraken has stale source hash)
  # home.packages = with pkgs; [ gitkraken ];
}
