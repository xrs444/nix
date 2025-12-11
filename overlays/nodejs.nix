{ inputs, ... }:
(final: prev: {
  nodejs = (inputs.nixpkgs-unstable.legacyPackages.${final.system}).nodejs_24;
  nodejs_24 = (inputs.nixpkgs-unstable.legacyPackages.${final.system}).nodejs_24;
})
