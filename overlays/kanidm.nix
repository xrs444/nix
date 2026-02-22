{ inputs, ... }:
(final: prev: {
  kanidm = (inputs.nixpkgs-unstable.legacyPackages.${final.stdenv.hostPlatform.system}).kanidm_1_9;
  kanidm_1_7 =
    (inputs.nixpkgs-unstable.legacyPackages.${final.stdenv.hostPlatform.system}).kanidm_1_9;
  kanidm_1_4 = final.kanidm_1_9; # or final.kanidm if you want
  kanidmWithSecretProvisioning_1_9 =
    (inputs.nixpkgs-unstable.legacyPackages.${final.stdenv.hostPlatform.system}).kanidm_1_9.override
      {
        enableSecretProvisioning = true;
      };
  kanidm-provision =
    (inputs.nixpkgs-unstable.legacyPackages.${final.stdenv.hostPlatform.system}).kanidm-provision;
})
