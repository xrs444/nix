{ inputs }:
{
  # Add custom packages from the 'pkgs' directory
  additions = final: _prev: import ../pkgs final.pkgs;

  # Modify existing packages
  modifications = final: prev: {
    # Example: override a package
    # some-package = prev.some-package.overrideAttrs (old: rec {
    #   # modifications
    # });
  };

  # Access packages from nixpkgs-unstable
  unstable-packages = final: _prev: {
    unstable = import inputs.nixpkgs-unstable {
      inherit (final) system;
      config.allowUnfree = true;
    };
  };
}