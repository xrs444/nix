# Summary: Determinate Nix integration with NixOS 25.11 compatibility
{ config, lib, pkgs, inputs, ... }:
let
  # Get the Determinate Nix package
  determinateNixPkg = inputs.determinate.inputs.nix.packages.${pkgs.stdenv.hostPlatform.system}.default;

  # Ensure it has the pname attribute for NixOS 25.11+ compatibility.
  # doCheck = false: the pname fix alone already forces this out of the
  # binary cache (changes the derivation hash), so a from-source rebuild is
  # unavoidable here — but there's no reason to also pay for nix's own test
  # suite on every build. Needed as of 2026-11-13: nix 2.34.9's
  # nix-util-tests-run fails `readLinkAt.works` in this sandboxed builder
  # environment, which failed the derivation and cascaded BUILD FAILED to
  # every host depending on nix.package (bug tbd).
  nixPackageWithPname = determinateNixPkg.overrideAttrs (oldAttrs: {
    pname = oldAttrs.pname or "nix";
    doCheck = false;
  });
in
{
  imports = [ inputs.determinate.nixosModules.default ];

  # Override nix.package to ensure pname attribute exists
  config = {
    nix.package = lib.mkForce nixPackageWithPname;
  };
}
