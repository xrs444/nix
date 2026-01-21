# Summary: NixOS module for vsftpd FTP server, configures per-host FTP service with secure defaults.
{
  hostname,
  lib,
  ...
}:
{
  imports = lib.optional (builtins.pathExists (./. + "/${hostname}.nix")) ./${hostname}.nix;
}
