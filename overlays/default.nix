{ inputs }:
{
  # Add custom packages from the 'pkgs' directory
  additions = final: _prev: import ../pkgs final.pkgs;

  # Access packages from nixpkgs-unstable (this needs to come first)
  unstable-packages = final: _prev: {
    unstable = import inputs.nixpkgs-unstable {
      inherit (final) system;
      config.allowUnfree = true;
    };
  };

  # Modify existing packages (this depends on unstable-packages)
  modifications = final: prev: {
    # Override kanidm to use the latest 1.7.x version from unstable
    kanidm = final.unstable.kanidm_1_7;
    
    # Example: override a package
    # some-package = prev.some-package.overrideAttrs (old: rec {
    #   # modifications
    # });
  };
}