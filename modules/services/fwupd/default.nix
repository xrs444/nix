# Summary: Enables fwupd (Linux Vendor Firmware Service client) so firmware
# updates can be checked/applied via `fwupdmgr` on every NixOS host.
{ ... }:
{
  services.fwupd.enable = true;
}
