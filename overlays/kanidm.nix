{ inputs, ... }:
(final: prev: {
  kanidm = (inputs.nixpkgs-unstable.legacyPackages.${final.system}).kanidm_1_8;
  kanidm_1_7 = (inputs.nixpkgs-unstable.legacyPackages.${final.system}).kanidm_1_8;
  kanidmWithSecretProvisioning_1_8 =
    (inputs.nixpkgs-unstable.legacyPackages.${final.system}).kanidm_1_8.override
      {
        enableSecretProvisioning = true;
      };
  kanidm-provision = (inputs.nixpkgs-unstable.legacyPackages.${final.system}).kanidm-provision;
})
