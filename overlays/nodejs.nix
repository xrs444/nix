{ inputs, ... }:
(final: prev: {
  nodejs = (inputs.nixpkgs-unstable.legacyPackages.${final.stdenv.hostPlatform.system}).nodejs_24;
  nodejs_24 = (inputs.nixpkgs-unstable.legacyPackages.${final.stdenv.hostPlatform.system}).nodejs_24;
})
