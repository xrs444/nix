# Summary: Phone config provisioning module; serves configs over HTTPS (nginx) and TFTP. Host-specific configs live in <hostname>.nix
{ hostname, lib, ... }:
{
  imports = lib.optional (builtins.pathExists (./. + "/${hostname}.nix")) ./${hostname}.nix;
}
