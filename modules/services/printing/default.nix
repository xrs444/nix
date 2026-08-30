# Summary: CUPS client and the xprn2 network print queue (HP Color LaserJet
# Pro MFP M281cdw) for workstation hosts.
{ hostname, lib, pkgs, ... }:
let
  printingHosts = [ "xdt1-t" "xlt2-s" ];
in
lib.mkIf (lib.elem hostname printingHosts) {
  services.printing.enable = true;

  hardware.printers.ensureDefaultPrinter = "xprn2";
  hardware.printers.ensurePrinters = [
    {
      name = "xprn2";
      deviceUri = "ipp://xprn2.lan/ipp/print";
      model = "everywhere";
      description = "HP Color LaserJet Pro MFP M281cdw";
    }
  ];

  # `lpadmin -m everywhere` builds the PPD from a live Get-Printer-Attributes
  # query, so ensure-printers.service fails outright when xprn2 is unreachable
  # (e.g. a laptop away from home). ExecCondition exiting non-zero makes
  # systemd skip the unit cleanly instead of leaving a failed unit; it retries
  # on the next boot.
  systemd.services.ensure-printers.serviceConfig.ExecCondition =
    "${pkgs.coreutils}/bin/timeout 5 ${pkgs.bash}/bin/bash -c 'exec 3<>/dev/tcp/xprn2.lan/631'";
}
