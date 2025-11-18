{ inputs, ... }:
(final: prev: {
  kanidm = (inputs.nixpkgs-unstable.legacyPackages.${final.system}).kanidm_1_7;
  kanidm_1_7 = (inputs.nixpkgs-unstable.legacyPackages.${final.system}).kanidm_1_7;
  kanidmWithSecretProvisioning_1_7 = (inputs.nixpkgs-unstable.legacyPackages.${final.system}).kanidm_1_7.override {
    enableSecretProvisioning = true;
  };
  kanidm-provision = (inputs.nixpkgs-unstable.legacyPackages.${final.system}).kanidm-provision;
})
