# Common VM guest configuration
# For hosts running as virtual machines
{
  config,
  lib,
  pkgs,
  ...
}:
{
  services.spice-vdagentd.enable = lib.mkDefault true;
  services.qemuGuest.enable = lib.mkDefault true;
}