{ inputs, ... }:
let
  unstablePkgs = system: inputs.nixpkgs-unstable.legacyPackages.${system};
in
{
  # This one brings our custom packages from the 'pkgs' directory
  additions = final: _prev: import ../pkgs {pkgs = final;};

  # This one contains whatever you want to overlay
  modifications = final: prev: {
    # Override default kanidm to use 1.7 from unstable
    kanidm = (unstablePkgs final.system).kanidm_1_7;
    
    # kanidm_1_7 for all kanidm servers (from unstable)
    kanidm_1_7 = (unstablePkgs final.system).kanidm_1_7;
    
    # kanidmWithSecretProvisioning_1_7 for provisioning server (xsvr1)
    kanidmWithSecretProvisioning_1_7 = (unstablePkgs final.system).kanidm_1_7.override {
      enableSecretProvisioning = true;
    };
    
    # kanidm-provision CLI tool - separate package from unstable to get 1.7
    kanidm-provision = (unstablePkgs final.system).kanidm-provision;
  };

  # When applied, the unstable nixpkgs set (declared in the flake inputs) will
  # be accessible through 'pkgs.unstable'
  unstable-packages = final: _prev: {
    unstable = import inputs.nixpkgs-unstable {
      system = final.system;
      config.allowUnfree = true;
    };
  };
}