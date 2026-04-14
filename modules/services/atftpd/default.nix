# Summary: TFTP provisioning server module; host-specific configs live in <hostname>.nix
{ hostname, lib, ... }:
{
  imports = lib.optional (builtins.pathExists (./. + "/${hostname}.nix")) ./${hostname}.nix;
}
