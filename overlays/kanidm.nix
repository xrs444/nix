{ inputs, ... }:
(final: prev: {
  kanidm = (inputs.nixpkgs-unstable.legacyPackages.${final.stdenv.hostPlatform.system}).kanidm_1_10;
  kanidm_1_7 =
    (inputs.nixpkgs-unstable.legacyPackages.${final.stdenv.hostPlatform.system}).kanidm_1_10;
  kanidm_1_4 = final.kanidm_1_10; # or final.kanidm if you want
  kanidmWithSecretProvisioning_1_10 =
    (inputs.nixpkgs-unstable.legacyPackages.${final.stdenv.hostPlatform.system}).kanidm_1_10.override
      {
        enableSecretProvisioning = true;
      };
  # Version-agnostic alias - update version once in the overlay
  kanidmWithSecretProvisioning = final.kanidmWithSecretProvisioning_1_10;
  kanidm-provision =
    (inputs.nixpkgs-unstable.legacyPackages.${final.stdenv.hostPlatform.system}).kanidm-provision;
})
