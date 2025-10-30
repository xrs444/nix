{ inputs }:
{
  # Add custom packages from the 'pkgs' directory
  additions = final: _prev: import ../pkgs final.pkgs;

  # Access packages from nixpkgs-unstable
  unstable-packages = final: _prev: {
    unstable = import inputs.nixpkgs-unstable {
      inherit (final) system;
      config.allowUnfree = true;
    };
  };

  # Modify existing packages
  modifications = final: prev: 
    let
      unstablePkgs = import inputs.nixpkgs-unstable {
        inherit (final) system;
        config.allowUnfree = true;
      };
    in {
      # Override kanidm to use the latest 1.7.x version from unstable
      kanidm = unstablePkgs.kanidm_1_7;
    };
}