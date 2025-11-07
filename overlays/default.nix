{ inputs, ... }:
let
  unstablePkgs = system: inputs.nixpkgs-unstable.legacyPackages.${system};
in
[
  # Overlay for kanidm-related package pinning/modification
  (final: prev: {
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
  })

  # Overlay for importing custom packages from ../pkgs directory
  (final: _prev: import ../pkgs { pkgs = final; })

  # Provide unstable as pkgs.unstable if needed
  (final: _prev: {
    unstable = import inputs.nixpkgs-unstable {
      system = final.system;
      config.allowUnfree = true;
    };
  })
]
