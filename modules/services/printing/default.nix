# Summary: CUPS client and the xprn2 network print queue (HP Color LaserJet
# Pro MFP M281cdw) for workstation hosts.
{ hostname, lib, pkgs, ... }:
let
  printingHosts = [ "xdt1-t" "xlt2-s" ];
in
lib.mkIf (lib.elem hostname printingHosts) {
  services.printing.enable = true;

  # Not using hardware.printers.ensurePrinters: its generated
  # ensure-printers.service has no failure tolerance, and xprn2 is often
  # asleep and won't answer the IPP Get-Printer-Attributes query that
  # `lpadmin -m everywhere` needs to build a driverless PPD (confirmed
  # 2026-08-30 on xlt2-s: "lpadmin: Unable to create PPD: No IPP attributes"
  # even though TCP:631 accepted the connection — a plain port check doesn't
  # catch this). A hard-failed unit here is fatal to nixos-rebuild switch
  # itself (nixos-rebuild-ng raises on a failed unit), which would break
  # every future deploy to a printing host whenever xprn2 happens to be
  # asleep. So this is a hand-rolled equivalent that always exits 0 and just
  # retries on the next switch/boot instead.
  systemd.services.ensure-xprn2 = {
    description = "Ensure xprn2 (HP M281cdw) CUPS queue exists";
    wantedBy = [ "multi-user.target" ];
    wants = [ "cups.service" ];
    after = [ "cups.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      ${pkgs.cups}/bin/lpadmin -p xprn2 -E \
        -v ipp://xprn2.lan/ipp/print -m everywhere \
        -D "HP Color LaserJet Pro MFP M281cdw" \
      && ${pkgs.cups}/bin/lpadmin -d xprn2 \
      || echo "xprn2 unreachable/not answering IPP -- will retry on next switch" >&2
    '';
  };
}
