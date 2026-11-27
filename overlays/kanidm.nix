{ inputs, ... }:
# Pin kanidm to a specific version from nixpkgs-unstable.
# To upgrade: change pinnedVersion to the new attribute (e.g. "kanidm_1_12")
# and verify before applying.
#
# Note: kanidm_1_4 and kanidm_1_7 aliases are required — the upstream nixpkgs
# kanidm module references pkgs.kanidm_1_4 as its default package value, so
# removing them breaks flake evaluation even when services.kanidm.package is
# overridden with mkForce.
let
  pinnedVersion = "kanidm_1_12";
in
(final: prev:
  let
    pkgsUnstable = inputs.nixpkgs-unstable.legacyPackages.${final.stdenv.hostPlatform.system};
    pinned = pkgsUnstable.${pinnedVersion};
  in
  {
    kanidm = pinned;
    kanidm_1_4 = pinned;
    kanidm_1_7 = pinned;
    # The kanidm module references pkgs.kanidm_1_12 / kanidmWithSecretProvisioning_1_12
    # by name. Without these, they resolve to the *stable* nixpkgs package (1.12.0,
    # which has the broken replication-cert issuer) and the unstable pin is bypassed.
    kanidm_1_12 = pinned;
    kanidmWithSecretProvisioning_1_12 = pinned.override { enableSecretProvisioning = true; };
    kanidmWithSecretProvisioning = pinned.override { enableSecretProvisioning = true; };
    kanidm-provision = pkgsUnstable.kanidm-provision;
  })
