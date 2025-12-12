# Summary: NixOS module for NixOS-specific packages, imports submodules and configures Kanidm server URI.
{ lib, ... }:
{
  imports = [
    ./cockpit/default.nix
    ./comin/default.nix
    ./kanidm/default.nix
  ];
}
