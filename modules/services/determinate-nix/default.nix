# Summary: Determinate Nix integration with NixOS 25.11 compatibility
{ config, lib, pkgs, inputs, ... }:
let
  # Get the Determinate Nix package
  determinateNixPkg = inputs.determinate.inputs.nix.packages.${pkgs.stdenv.system}.default;

  # Ensure it has the pname attribute for NixOS 25.11+ compatibility
  nixPackageWithPname = determinateNixPkg.overrideAttrs (oldAttrs: {
    pname = oldAttrs.pname or "nix";
  });
in
{
  imports = [ inputs.determinate.nixosModules.default ];

  # Override nix.package to ensure pname attribute exists
  config = {
    nix.package = lib.mkForce nixPackageWithPname;
  };
}
